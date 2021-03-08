require 'rubygems'
require 'chef/encrypted_data_bag_item'
require 'chef/cookbook/metadata'
require 'rspec/core/rake_task'
require 'foodcritic'
require 'kitchen'
require_relative '../RakeHelpers/default_args'
load './buildtools/chef/deep_merge.rb'
load './buildtools/terraform/terraform_rakefile.rb'

#--------------------------------------
# ACTUAL CHEF BUILD TASKS
#--------------------------------------
def metadata_path
  File.join(Rake.original_dir, 'metadata.rb')
end

def read_metadata
  if File.exist?(metadata_path)
    md = Chef::Cookbook::Metadata.new
    md.from_file metadata_path
    md
  else
    puts "Could not find metadata.rb in #{Rake.original_dir}, are you in a cookbook?"
    exit 1
  end
end

desc 'Set version number for the cookbook'
task :version_cookbook, [:build_number] do |_, args|
  md = read_metadata
  fi = File.read(metadata_path)
  # fi = File.read(md.source_file) <- only supported by ChefDK 3+

  puts "Setting cookbook #{File.basename(Dir.pwd)} version to #{args.build_number}"
  fi.gsub!(/(?<prefix>version\W+["'])#{md.version.to_s}/, "\\k<prefix>#{args.build_number}")

  File.open(metadata_path, 'w') { |file| file.puts fi }
end

desc 'Run Ruby style checks'
task :ruby_style_check do
  # --force-exclusion ensures exclusions in .rubocop.yml are honored. These exclusions are typically
  # used to exclude BuildTools from rubocop checks
  sh 'rubocop --force-exclusion "**/*.rb"'
end

desc 'Try to auto-correct  Ruby style failures'
task :fix_ruby_style_errors do
  # --force-exclusion ensures exclusions in .rubocop.yml are honored. These exclusions are typically
  # used to exclude BuildTools from rubocop checks, then correct any issues where possible
  sh 'rubocop --force-exclusion "**/*.rb" --auto-correct'
end

desc 'Run Chef style checks'
FoodCritic::Rake::LintTask.new(:chef_style_check) do |t|
  t.options = {
    fail_tags: ['any'],
    tags: %w[~opensource]
  }
end

desc 'Run ChefSpec tests'
RSpec::Core::RakeTask.new(:chef_spec_tests) do |t|
  t.pattern = './spec/**/*_spec.rb'
end

desc 'Ensure we have latest cookbooks we depend on'
task :prepare_dependencies, [:build_number] do
  sh 'berks install'
end

desc 'To keep things easy to read we will generate a Test Kitchen YAML file based on ' \
    'templates + user YAML'
task :generate_kitchen_yaml do
  md = read_metadata
  target_os = ['common']
  md.platforms.each_key do |key|
    target_os << (key == 'windows' ? 'windows' : 'linux')
  end
  # Merge the base configs with the user config
  config_files_previx = ENV['CHEFDK_CONFIG_PREFIX']
  config_files = target_os.uniq.map do |os|
    File.join('BuildTools', 'Chef', "#{config_files_previx}base_#{os}_kitchen.yml")
  end
  config_files << (ENV['KITCHEN_YAML'] || '.kitchen.yml')
  merged_settings = {}
  config_files.each do |file_name|
    file_contents = YAML.load_file(File.join(Rake.original_dir, file_name))
    merged_settings.deep_merge! file_contents do |current_key, this_value, other_value|
      current_key == 'platforms' ? (this_value + other_value) : other_value
    end
  end

  # Make sure any injected values aren't wrapped into strings
  merged_settings_to_write = merged_settings.to_yaml
  merged_settings_to_write.delete!('"')

  # Write the generated YAML and direct Test Kitchen to use it
  File.open('generated_kitchen.yml', 'w') { |file| file.puts merged_settings_to_write }
  ENV['KITCHEN_YAML'] = 'generated_kitchen.yml'
end

desc 'Run full Test Kitchen life-cycle (converge, verify, destory)'
task full_test_kitchen: %i[kitchen_converge_verify kitchen_destroy]

desc 'Run Test Kitchen but do not destroy after the run completes'
task kitchen_converge_verify: %i[kitchen_converge kitchen_verify]

desc 'Run Test Kitchen Converge'
task kitchen_converge: %i[prepare_dependencies generate_kitchen_yaml] do
  # Are we using Terraform or another provisioner?
  if !ENV['CHEFDK_CONFIG_PREFIX'].nil? && ENV['CHEFDK_CONFIG_PREFIX'].start_with?('tf')
    # Use Terraform to provision the boxes
    prepare_terraform_variables
    Rake::Task['tf_apply'].invoke

    # Generate kitchen config files based off the Terraform state
    convert_terraform_into_kitchen

    # Loop through each suite and converge sequentially, ensuring we set the password for
    # each as they will all have different root passwords
    file_contents = YAML.load_file(File.join(Rake.original_dir, '.kitchen.yml'))
    file_contents['suites'].each do |suite|
      if suite['includes'].start_with?('win')
        ENV['SECRET_WINDOWS_ADMIN_PASSWORD'] = "\"#{get_password_for_suite suite['name']}\""
      else
        ENV['SECRET_CENTOS_ROOT_PASSWORD'] = "\"#{get_password_for_suite suite['name']}\""
      end
      sh "kitchen converge #{suite['name']}"
    end
  else
    # PB_TODO: This is now commented out because in ChefDK 3.7 local files are locked when trying
    #          to converge multiple suites in parallel. Hopefully this will be resolved in future
    #          releases so want to leave this here as a note so we can add back in. As this now
    #          runs sequentially all multiple suite cookbooks will take much longer to build.
    # Run up to four suites concurrently to speed up the testing cycle
    # sh 'kitchen converge -c 4'
    sh 'kitchen converge'
  end
end

def prepare_terraform_variables
  # Don't clean up machine automatically
  ENV['TF_DISABLE_CLEANUP'] = '1'

  # Setup some common variables for identifying the machine
  ENV['TF_VAR_user_initials'] = ENV['USERINITIALS']
  ENV['TF_VAR_annotation'] = "Test Kitchen VM by #{ENV['USERNAME'].upcase} on #{Time.now}"
end

def convert_terraform_into_kitchen
  vm_name = nil
  machine_ip = nil

  # We want to match the Test Kitchen config with the Terraform state
  tk_file_contents = YAML.load_file(File.join(Rake.original_dir, '.kitchen.yml'))
  tf_file_contents = YAML.load_file(File.join(Rake.original_dir, 'terraform.tfstate'))

  # Match each Test Kitchen suite with its corresponding module in the TF state file
  tk_file_contents['suites'].each do |suite|
    tf_file_contents['resources'].each do |moduleinfo|
      if moduleinfo['module'] == "module.#{suite['name']}"
        machine_ip = moduleinfo['instances'][0]['attributes']['default_ip_address']
        vm_name = moduleinfo['instances'][0]['attributes']['name']
      end
    end

    # Write information into Test Kitchen info file so Chef Zero can run against it
    write_kitchen_file(suite['name'], suite['includes'], machine_ip, vm_name)
  end
end

def write_kitchen_file(suite_name, suite_type, machine_ip, vm_name)
  kitchen_dir = File.join(Rake.original_dir, '.kitchen')
  Dir.mkdir(kitchen_dir) unless Dir.exist?(kitchen_dir)
  tk_file = File.join(kitchen_dir, "#{suite_name}-#{suite_type}.yml")
  tk_file_contents = File.new(tk_file, 'w')
  tk_file_contents.puts('---')
  if suite_type.start_with?('win')
    tk_file_contents.puts("hostname: #{vm_name}.bfl.local")
  else
    tk_file_contents.puts("hostname: #{machine_ip}")
  end
  tk_file_contents.puts("vm_name: #{vm_name}")
  tk_file_contents.puts('last_action: create')
  tk_file_contents.puts('last_error:')
  tk_file_contents.close
end

def get_password_for_suite(suite_name)
  admin_password = nil

  tf_file_contents = YAML.load_file(File.join(Rake.original_dir, 'terraform.tfstate'))
  tf_file_contents['resources'].each do |moduleinfo|
    if moduleinfo['module'] == "module.#{suite_name}.module.local_admin_password"
      admin_password = moduleinfo['instances'][0]['attributes']['result']
    end
  end
  admin_password
end

desc 'Run Test Kitchen Verify'
task kitchen_verify: %i[generate_kitchen_yaml] do
  # Test output is hard to read when run concurrently so run sequentially
  sh 'kitchen verify'
end

desc 'Clean up after Test Kitchen run'
task kitchen_destroy: %i[generate_kitchen_yaml] do
  # Run up to four suites concurrently to speed up the testing cycle
  sh 'kitchen destroy -c 4'

  # If we are using Terraform as the provisioner then tidy up the machine(s) now
  if !ENV['CHEFDK_CONFIG_PREFIX'].nil? && ENV['CHEFDK_CONFIG_PREFIX'].start_with?('tf')
    prepare_terraform_variables
    Rake::Task['tf_destroy'].invoke
  end
end

desc 'List TK instances that will be spun up'
task kitchen_list: [:generate_kitchen_yaml] do
  sh 'kitchen list'
end

desc 'Upload all required cookbooks to the Chef Server'
task publish_cookbook: [:prepare_dependencies] do
  # TODO: remove no-ssl-verify!
  sh 'berks upload --no-ssl-verify'
end

self.default_args = { build_number: '0.0.0' }
