require 'json'
require 'fileutils'
require 'English'
require_relative './docker_structures.rb'

# This contains all the Docker related tasks for Beazley
class Docker
  DEFAULT_DOCKER_FILE = File.join(Rake.original_dir, 'dockerfile')

  # Initialising the class will set the Docker daemon for all subsequent commands
  def initialize(daemon)
    @daemon = daemon
    puts "Using Docker daemon: #{@daemon}"
  end

  # Run Docker build to build and generate Docker image
  def build(build_number, container)
    docker_cmd = 'docker '\
      'build '\
      "--file #{container.dockerfile} " \
      "-t \"#{container.name}:#{build_number}\" "\
      '.'
    execute_command docker_cmd
  end

  # Run the Docker build for the "builder" stage only and stop
  def build_stage_only(build_number, container)
    docker_cmd = 'docker '\
      'build '\
      "--file #{container.dockerfile} " \
      '--target builder ' \
      "-t \"#{container.name}_builder:#{build_number}\" "\
      '.'
    execute_command docker_cmd
  end

  def copy_from_container_to_local(build_number, container, container_directory, host_directory)
    # Ensure local directory exists first
    FileUtils.mkdir_p host_directory

    # Copy from container to local and handle the fact that Robocopy returns any exit code
    # >7 = Error. This is because Robocopy uses exit codes 0 - 7 to signal if files were
    # copied, updated, no action etc.
    docker_cmd = 'docker '\
      'run ' \
      '--rm ' \
      '--mount ' \
        'type=bind,' \
        "source=#{host_directory}," \
        'target=c:/CopyToHost ' \
      "#{container.name}_builder:#{build_number} " \
      "Robocopy #{container_directory} C:\\CopyToHost /MIR"
    execute_command docker_cmd
    return if $CHILD_STATUS.exitstatus < 8

    puts 'Failed to transfer files from container back to this host.'
    exit 99
  end

  # Sign in to the remote registry using the more secure password-stdin approach although it is a
  # little harder to read it is more secure as the password will not appear in histories or logs.
  # There are still better approaches that should be adopted later on.
  def sign_in_to_registry(registry)
    docker_cmd = 'PowerShell -Command "' \
    "'#{registry.password}' | docker " \
    'login ' \
    "#{registry.name} " \
    "-u '#{registry.username}' "\
    '--password-stdin' \
    '"'
    execute_command docker_cmd, [registry.password]
  end

  # Tag the image to match where we are publishing
  def tag(build_number, container)
    docker_cmd = 'docker '\
      'tag '\
      "#{container.name}:#{build_number} " \
      "#{container.registry.name}/#{container.name}:#{build_number}"
    execute_command docker_cmd
  end

  # Push image to a registry
  def push(build_number, container)
    docker_cmd = 'docker '\
      'push '\
      "#{container.registry.name}/#{container.name}:#{build_number}"
    execute_command docker_cmd
  end

  # Publish image to a registry
  def publish(build_number, container)
    # Ensure we have access to the registry before trying to push
    # sign_in_to_registry(container.registry)

    # First we need to tag the image to match where we are publishing
    tag(build_number, container)

    # Now we can push to the registry
    push(build_number, container)
  end

  # Output the command we are going to run (redact sensitive info) and then execute the command
  def execute_command(docker_cmd, sensitive_strings = [])
    ENV['DOCKER_HOST'] = @daemon
    redacted_cmd = docker_cmd.dup
    sensitive_strings.each do |sensitive_string|
      redacted_cmd.gsub!(sensitive_string, '**SENSITIVE**')
    end
    puts redacted_cmd
    system docker_cmd
  end
end
