#--------------------------------------
# Global Variables
#--------------------------------------
require_relative '../RakeHelpers/secretserver.rb'
require_relative './beazley_terraform.rb'
require_relative './var_files.rb'

SOLUTION_DIR = Rake.original_dir
BUILD_TOOLS_DIR = File.join(SOLUTION_DIR, 'BuildTools')
SECRET_SERVER = SecretServer.new(ENV['SECRET_SERVER_USERNAME'], ENV['SECRET_SERVER_PASSWORD'], \
                                 secret_file: File.join(SOLUTION_DIR, 'secrets.json'))

# Find all of the global TF Var files and ensure they are used for each TF call
VarFiles.add_path Dir.glob(File.join(BUILD_TOOLS_DIR, '/Terraform', 'autos', '*'))

#--------------------------------------
# TOP-LEVEL BUILD TASKS (used in CI)
#--------------------------------------
task :setup_dev_experience do
  puts 'Please ensure you have Terraform installed.'
end

#--------------------------------------
# Terraform Specific Tasks
#--------------------------------------
# NOTE
# Backends are not currently recommended for general dev work.
# The process for implementing a TF module should have and test the backend configuration.
# State should be considered disposable outside of an automated pipeline.
# It can be set up/configured, but its for the developer to do and seek guidance
task :tf_init, [:module] => [:setup_tf_invoker] do
  TF.exec_terraform('init')
end

task :setup_tf_invoker, [:module] do |_t, args|
  # Check to see whether we are running in the root (local dev) or a
  # different path (example build, tc PR/master build of default) as a module
  module_path = args[:module].nil? ? '' : File.expand_path(args[:module])
  ENV['TF_module_path'] = module_path

  # Find if we are using Terraform on path or local copy
  name = 'terraform.exe'
  home_of_terraform = if File.exist?("./#{name}")
                        "./#{name}"
                      else
                        [name,
                         *ENV['PATH'].split(File::PATH_SEPARATOR).map do |p|
                           File.join(p, name)
                         end].find do |f|
                          File.executable?(f)
                        end
                      end
  raise 'Could not locate Terraform on path or locally!' if home_of_terraform.nil?

  puts "Found Terraform here: #{home_of_terraform}"

  # By default, if we are using a module, any tfvar files in the path will be included without
  # needing to be explictly added.
  TF = BeazleyTerraform.new(home_of_terraform, module_path, VarFiles.paths)
end

task :tf_plan, [:module] => [:tf_init] do
  TF.exec_terraform('plan')
end

task :tf_apply, [:module] => [:tf_init] do
  TF.exec_terraform('apply', flags: ['auto-approve'])
end

desc 'Runs some automated tests based on the default example'
task :tf_test, [:module] do |_t, args|
  case args[:module]
  when nil
    Rake::Task['specs:local:all'].invoke
  when %r{examples\/[\w\d_-]+} # Note, no support for nested modules atm
    Rake::Task["specs:#{args[:module].split('/')[1]}:all"].invoke
  else
    # REFAC: should this error if no tests? Maybe with override flag?
    puts "No tests for #{args[:module]} mapped"
  end
end

task :tf_taint, %i[module resource_name] => [:tf_init] do |_t, args|
  raise 'Must supply a resource name' if args[:resource_name].nil?

  # TODO: support multiple taints...
  TF.exec_terraform('taint', args[:resource_name])
end

# TODO: support untainting

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

task :tf_destroy, %i[module forced] => [:tf_init] do |_t, args|
  puts 'Forced cleanup running' if args[:forced]
  TF.exec_terraform('destroy', flags: ['auto-approve'])
end

task :cleanup do
  return unless $ERROR_INFO.nil?

  # If we are publishing the application, then cleanup should have occured during the bvp step
  # Should only be true on publish step
  exit if defined?(TF).nil?

  # If we want the infra to persist then we set an env var
  exit if to_bool(ENV['TF_DISABLE_CLEANUP'])

  Rake::Task['tf_destroy'].invoke(TF.module_path, true)
end

# Default namespace configured to read tests from default_spec.rb
namespace :specs do
  require 'rspec/core/rake_task'
  namespace :local do
    # The default spec executes the tests against the local config (root of repo)
    RSpec::Core::RakeTask.new(:all) do |t|
      t.pattern = Dir.glob(['./test/*_spec.rb', './BuildTools/Terraform/local_spec.rb'])
      t.rspec_opts = '--format documentation' # Always print the test output
    end
  end

  namespace :default do
    # A example module spec. This sets up the query to TF output based on the module being
    # tested. This one below is for the TC Build pipeline. Test the default example, with the
    # default tests.
    RSpec::Core::RakeTask.new(:all) do |t|
      t.pattern = Dir.glob(['./test/*_spec.rb', './test/config/default.rb'])
      t.rspec_opts = '--format documentation'
    end
  end
end

def to_bool(val)
  return true if [1, true, '1', 'true', 'y', 'yes'].include?(val)
end

# Always check for cleanup in case of failure. We don't want to leave random infra lying around
at_exit { Rake::Task[:cleanup].invoke }
