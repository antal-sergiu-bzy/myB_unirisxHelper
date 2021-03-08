require 'bundler/setup'
require 'albacore'
require 'rake/clean'
require 'fileutils'

require_relative 'buildtools/rakehelpers'               # General purpose helpers
require_relative 'buildtools/rakedeploymenthelpers'     # Build, Package and Deployment helpers


#--------------------------------------
# VARIABLES
#--------------------------------------
SOLUTION_NAME = 'myBeazley.UnirisxHelper.sln'.freeze
SOLUTION_DIR = Rake.original_dir

BUILD_TOOLS_DIR = File.join(SOLUTION_DIR, 'BuildTools')
OCTOPUS_DEPLOY = OctopusDeploy.new(ENV['Octopus_Server'].to_s, ENV['Octopus_API_Key'].to_s)
NUGET_ARTIFACTS = Nuget.new(ENV['NuGet_Server'].to_s, ENV['NuGet_API_Key'].to_s)
NUGET_DEPLOYMENT_ARTIFACTS = Nuget.new(ENV['NuGet_Deployments_Server'].to_s, ENV['NuGet_Deployments_API_Key'].to_s)

BUILD_OUTPUT_BASE_DIR = File.join(SOLUTION_DIR, 'BuildOutput/')
BUILD_OUTPUT_TEST_DIR = File.join(BUILD_OUTPUT_BASE_DIR, 'TestResults/')
BUILD_OUTPUT_NUGET_DIR = File.join(BUILD_OUTPUT_BASE_DIR, 'nuget.bfl.local/')
BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR = File.join(BUILD_OUTPUT_BASE_DIR, 'nugetdeployments.bfl.local/')

RELEASE_NOTES_FILE = File.join(SOLUTION_DIR, 'ReleaseNotes.md')

CONFIG = OpenStruct.new

def init
  # Allow parallel execution of tests
  # CONFIG.parallelization = ENV['IntegrationTest_OctopusParallelization'] || 3

  # Determine if PR or master build
  CONFIG.branch_name = ENV['Branch_Name']
  CONFIG.pull_request_number = get_pr_identifier(CONFIG.branch_name)

  # If master build then use default deployments with no overrides etc
  CONFIG.INTEGRATION_DEPLOYMENT_VARIABLES = {}
  return if CONFIG.pull_request_number.zero?

  # Create overrides for PR deployment
  CONFIG.INTEGRATION_DEPLOYMENT_VARIABLES = {
    :"build.override" => "_PR#{CONFIG.pull_request_number}"
  }
end

# This should be moved into another dependency
def get_pr_identifier(branch_name)
  puts "Resolving PR identifier for: #{branch_name}"
  return 0 if branch_name.nil? || (branch_name.include? 'master')

  branch_name.split('/')[0].to_i
end
init

arg_defaults = {
  build_number: '0.0.0',
  msbuild_config: :Release
}

# Nuget package setup
MYBEAZLEY_UNIRISXHELPER_TESTING_PACKAGE = PackageInformation.new(
  name: 'myBeazley.UnirisxHelper',
  artifact_store: NUGET_ARTIFACTS,
  source: File.join(SOLUTION_DIR, 'myBeazley.UnirisxHelper.Testing',
                    'myBeazley.UnirisxHelper.Testing.nuspec'),
  output_folder: BUILD_OUTPUT_NUGET_DIR
)

MYBEAZLEY_UNIRISXHELPER_DataTransferObj_PACKAGE = PackageInformation.new(
  name: 'myBeazley.UnirisxHelper.DataTransferObj',
  artifact_store: NUGET_ARTIFACTS,
  source: File.join(SOLUTION_DIR, 'myBeazley.UnirisxHelper.DataTransferObj',
                    'myBeazley.UnirisxHelper.DataTransferObj.nuspec'),
  output_folder: BUILD_OUTPUT_NUGET_DIR
)

MYBEAZLEY_UNIRISXHELPER_UIAUTO_PACKAGE = PackageInformation.new(
  name: 'myBeazley.UnirisxHelper.UIAuto',
  artifact_store: NUGET_ARTIFACTS,
  source: File.join(SOLUTION_DIR, 'myBeazley.UnirisxHelper.UIAuto',
                    'myBeazley.UnirisxHelper.UIAuto.nuspec'),
  output_folder: BUILD_OUTPUT_NUGET_DIR
)

PACKAGES_INFO = [
  MYBEAZLEY_UNIRISXHELPER_TESTING_PACKAGE,
  MYBEAZLEY_UNIRISXHELPER_DataTransferObj_PACKAGE,
  MYBEAZLEY_UNIRISXHELPER_UIAUTO_PACKAGE,
].freeze

#---CLEAN----
CLOBBER.include(BUILD_OUTPUT_BASE_DIR)
directory BUILD_OUTPUT_BASE_DIR => :clobber

#--------------------------------------
# BUILD TASKS
#--------------------------------------

task default: %w[build]
task :build_valid_packages, %i[build_number msbuild_config] => %i[build validate build_packages create_releases]
task :publish, %i[build_number msbuild_config] => %i[publish_packages]
task :build, %i[build_number msbuild_config] => %i[msbuild build_database]
task :validate, %i[build_number msbuild_config] => %i[validate_release_notes run_tests]

task :validate_release_notes do |_cmd, _args|
  contents = File.read(RELEASE_NOTES_FILE)

  puts 'Release notes: ' + contents
  if contents == 'REPLACE CONTENT'
    throw 'Please replace default text in ReleaseNotes.md with information relevant to this release'
  elsif contents.to_s.empty?
    throw 'Release notes are empty. Please add some text to top of the release note to describe the latest release.'
  end

  puts 'Release notes text ok'
end

# only needed because rakehelper depends on :build_release for :deploy_to_local
task :build_release do |_t, args|
  task(:build).invoke(args.build_number, :Release)
end

msbuild :msbuild, %i[build_number msbuild_config] => %i[clobber nuget_restore version_assembly_file] do |msb, args|
  puts "args=#{args.inspect}"
  apply_build_defaults_to msb
  msb.nologo
  msb.solution = File.join(SOLUTION_DIR, SOLUTION_NAME)
  msb.targets = %i[Clean Build]
  msb.properties = { configuration: args.msbuild_config }
end

task :build_database do
  puts 'No databases to build'
end

desc 'Restore NuGet Packages required for Building'
exec :nuget_restore do |cmd, _args|
  puts 'Restoring NuGet Packages...'

  ENV['EnableNuGetPackageRestore'] = 'true'
  cmd.command = File.join(BUILD_TOOLS_DIR, 'NuGet.exe')
  cmd.parameters = [
    'restore',
    "\"#{File.join(SOLUTION_DIR, SOLUTION_NAME)}\""
  ]
end

desc 'Updates AssemblyInfo.cs file with desired version information'
assemblyinfo :version_assembly_file, [:build_number] do |asm, args|
  common_assembly_file = File.join(SOLUTION_DIR, 'CommonAssemblyInfo.cs')
  asm.version = args.build_number
  asm.file_version = args.build_number
  asm.output_file = common_assembly_file
  asm.input_file = common_assembly_file
end

desc 'Run any tests that are required'
task run_tests: :msbuild do |_nunit|
  puts 'No tests to execute.'
end

desc 'Sets up the developers local machine so they can develop the solution'
task :setup_dev_experience, [:server, :port_number] do |_sql, _args|
  puts 'Nothing special required!'
end

task :build_packages, %i[build_number msbuild_config] => :build do |_cmd, args|
  mkdir_p(BUILD_OUTPUT_NUGET_DIR)
  mkdir_p(BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR)

  # Create package artifacts
  PACKAGES_INFO.each do |package|
    puts "Creating #{package.name}.#{args.build_number}.nupkg..."
    package.artifact_store.create_package(args.build_number, package.source, package.output_folder)
  end
end

task :publish_packages, [:build_number] do |_cmd, args|
  # Publish package artifacts
  PACKAGES_INFO.each do |package|
    full_file_path = File.join(package.output_folder, "#{package.name}.#{args.build_number}.nupkg")
    puts "Pushing #{full_file_path}..."
    package.artifact_store.push_package(full_file_path)
  end
end

task :create_releases, [:build_number] do |_cmd|
  puts 'No releases to create'
end

#--------------------------------------
# UTILITY
#--------------------------------------
def get_runner_directory
  search_dir = File.join(SOLUTION_DIR, 'packages')

  powershell_command = %("Get-ChildItem #{search_dir} NUnit.Runners* -Recurse -Directory |
                        Select-Object -First 1 -ExpandProperty FullName")

  search_command = [
    'powershell',
    '-command',
    powershell_command
  ].join(' ')

  "%x(#{search_command}).strip"
end

# This needs to be at the end of the file
self.default_args = arg_defaults
