require 'bundler/setup'
require 'rake/clean'
require 'fileutils'
require 'English'

# General purpose helpers
require_relative '..\RakeHelpers\nuget'
require_relative '..\RakeHelpers\octopusdeploy'
require_relative '..\RakeHelpers\secretserver'
require_relative '..\RakeHelpers\teamcity'

#--------------------------------------
# General Build tasks
#--------------------------------------
task :set_backend_config do |_t, _args|
  nested_folder_name = TeamCity.running_on_agent? ? ENV['git_repository'] : File.basename(Dir.pwd)
  # Allow a project to override subpath default if required
  subpath = ENV['subpath'].nil? ? "#{ENV['USERNAME']}/#{nested_folder_name}" : ENV['subpath']

  puts "subpath set to: #{subpath}"

  # If in TeamCity, use the password restored by secret server otherwise user should set
  ENV['BACKEND_PASSWORD'] =
    if TeamCity.running_on_agent?
      ENV['tc_backend_password']
    else
      ENV['SECRET_SERVER_PASSWORD']
    end

  BACKEND_CONFIG = '-backend=true ' \
    "-backend-config=\"subpath=#{subpath}\" " \
    "-backend-config=\"password=#{ENV['BACKEND_PASSWORD']}\" " \
    "-backend-config=\"username=#{ENV['USERNAME']}\""

  puts "-backend-config set to: '#{BACKEND_CONFIG.gsub(/password=.+"/, 'password=*********"')}'"
end

task :print_module_reference_usage, [:build_number] do |_t, args|
  module_name = ENV['git_repository'] || File.basename(File.expand_path('.'))
  output = %(
Nothing to publish, this commit will be labelled with the build number
To reference this module version, place the following config in your configuration:
module #{module_name} {
  source = \"git::http://git.bfl.local/Terraform/#{module_name}.git?ref=v#{args[:build_number]}\"
  args...
}
  )
  puts output
end

#--------------------------------------
# Terraform build tasks
#--------------------------------------
desc 'Initialises terraform ready for use'
task tf_init: %i[set_backend_config] do |_t, _args|
  system(".\\terraform init -reconfigure -upgrade #{BACKEND_CONFIG}")
end

desc 'Runs terraform plan, shows  what would happen if current configuration was applied'
task tf_plan: %i[tf_init] do |_t, _args|
  system('.\terraform plan')
end

desc 'Runs terraform apply in an automated fashion where prompts are not required'
task tf_apply: %i[tf_init] do |_t, _args|
  system('.\terraform apply -auto-approve')
end

desc 'Runs terraform output for usage in json format during testing'
task :tf_output do |_t, _args|
  ENV['TF_CLI_ARGS'] = nil # Blank -input=false as its not supported by output command
  File.delete(OUTPUT_FILE) if File.exist? OUTPUT_FILE
  system(".\\terraform output -json > #{OUTPUT_FILE}")
end

desc 'Forces terraform destroy to delete anything it is aware of'
task :tf_destroy, %i[cleanup] => %i[tf_init] do |_t, args|
  puts 'Terraform destroy executing via cleanup process' if args[:cleanup]
  system('.\terraform destroy -auto-approve')
end

def to_bool(val)
  return true if [1, true, '1', 'true', 'y', 'yes'].include?(val)
end

task :cleanup do
  return unless $ERROR_INFO.nil?

  exit if to_bool(ENV['TF_DISABLE_CLEANUP'])

  Rake::Task[:tf_destroy].invoke(true)
end

at_exit { Rake::Task[:cleanup].invoke }
