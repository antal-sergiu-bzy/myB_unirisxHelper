require 'bundler/setup'
require 'albacore'
require 'rake/clean'
require 'fileutils'

require_relative '../rakehelpers' # General purpose helpers

# SolidOps variables
SOLUTION_DIR = Rake.original_dir
BUILD_TOOLS_DIR = File.join(SOLUTION_DIR, 'BuildTools')
RELEASE_NOTES_FILE = File.join(SOLUTION_DIR, 'ReleaseNotes.md')
OCTOPUS_DEPLOY = Octopus_Deploy.new((ENV['Octopus_Server']).to_s, (ENV['Octopus_API_Key']).to_s)
NUGET_DEPLOYMENT_ARTIFACTS = Nuget.new(
  ENV['NuGet_Deployments_Server'].to_s, ENV['NuGet_Deployments_API_Key'].to_s
)

# Build artifacts
BUILD_OUTPUT_BASE_DIR = File.join(SOLUTION_DIR, 'BuildOutput')
BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR = File.join(BUILD_OUTPUT_BASE_DIR, 'nugetdeployments.bfl.local')

# Docker specific variables
DOCKER_REPOSITORY = 'beazley-docker.artifactory.bfl.local'.freeze
DOCKER_LINUX_BUILD_DAEMON = 'tcp://TK-DOCKER-LIN1.bfl.local:2375'.freeze
DOCKER_WINDOWS_BUILD_DAEMON = 'tcp://TK-DOCKER-WIN1.bfl.local:2375'.freeze
DOCKER_FILES = File.join(SOLUTION_DIR, 'docker')

#--------------------------------------
# ACTUAL DOCKER BUILD TASKS
#--------------------------------------
desc 'Build the Docker image'
exec :build_docker_image, [:build_number] => :build do |cmd, args|
  puts 'Building Docker image...'

  cmd.command = 'docker.exe'
  cmd.parameters = [
    'build',
    '-t',
    "\"#{DOCKER_IMAGE_NAME}:#{args.build_number}\"",
    DOCKER_FILES
  ]
end

desc 'Publisher the Docker image to a Docker Registry'
exec :publish_docker_image, [:build_number] => %i[login_to_publisher tag_image] do |cmd, args|
  puts 'Publishing Docker image...'

  cmd.command = 'docker.exe'
  cmd.parameters = [
    'push',
    "\"#{DOCKER_REPOSITORY}/#{DOCKER_IMAGE_NAME}:#{args.build_number}\""
  ]
end

desc 'Tag the Docker image ready to be stored in a Docker Registry'
exec :tag_image, [:build_number] do |cmd, args|
  puts 'Tagging Docker image for publisher...'

  cmd.command = 'docker.exe'
  cmd.parameters = [
    'tag',
    "\"#{DOCKER_IMAGE_NAME}:#{args.build_number}\"",
    "\"#{DOCKER_REPOSITORY}/#{DOCKER_IMAGE_NAME}:#{args.build_number}\""
  ]
end

desc 'Log into the Docker Registry we wish to store our image'
task :login_to_publisher, [:build_number] do
  puts 'Signing in to Publisher...'

  sign_in_cmd = 'docker.exe '\
    'login '\
    "#{DOCKER_REPOSITORY} "\
    '-u ' \
    "\"#{ENV['DOCKER_REGISTRY_USER'].sub('bfl\\', '')}\" "\
    '-p '\
    "\"#{ENV['DOCKER_REGISTRY_PASSWORD']}\" "
  puts sign_in_cmd.gsub(ENV['DOCKER_REGISTRY_PASSWORD'], '[PROTECTED]')
  system sign_in_cmd
end

#--------------------------------------
# HELPER / GENERIC TASKS
#--------------------------------------
CLOBBER.include(BUILD_OUTPUT_BASE_DIR)
directory BUILD_OUTPUT_BASE_DIR => :clobber

desc 'Ensure release notes have been created so that Octopus Deploy can raise standard changes'
task :validate_release_notes do
  contents = File.read(RELEASE_NOTES_FILE)

  puts 'Release notes: ' + contents
  if contents == 'REPLACE CONTENT'
    throw 'Please replace default text in ReleaseNotes.md with information relevant to this release'
  elsif contents.to_s.empty?
    throw 'Release notes are empty. Please add some text to top of the release note to ' \
      'describe the latest release.'
  end

  puts 'Release notes text okay.'
end

desc 'Build any deployment helpers into NuGet package'
task :build_packages, [:build_number] => [:build] do |_, args|
  mkdir_p(BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR)

  # Create package artifacts
  package_source = File.join(DOCKER_FILES, "#{OCTOPUS_DEPLOY_PROJECT}.nuspec")
  NUGET_DEPLOYMENT_ARTIFACTS.create_package(
    args.build_number, package_source, BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR
  )
end

desc 'Publish deployment helper NuGet package'
task :publish_packages, [:build_number] do |_, args|
  full_file_path = File.join(BUILD_OUTPUT_NUGET_DEPLOYMENTS_DIR,
                             "#{OCTOPUS_DEPLOY_PROJECT}.#{args.build_number}.nupkg")
  puts "Pushing #{full_file_path}..."
  NUGET_DEPLOYMENT_ARTIFACTS.push_package(full_file_path)
end

desc 'Create our release candidate in Octopus Deploy'
task :create_releases, [:build_number] do |_, args|
  OCTOPUS_DEPLOY.create_versioned_release(
    args.build_number, args.build_number, OCTOPUS_DEPLOY_PROJECT,
    releasenotesfile: RELEASE_NOTES_FILE
  )
end

self.default_args = { build_number: '0.0.0' }
