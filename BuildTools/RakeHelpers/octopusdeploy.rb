require 'json'
require 'fileutils'

class OctopusDeploy
  def initialize(octopus_deploy_server, api_key)
    @octopus_deploy_server = octopus_deploy_server
    @api_key = api_key
    @octo_exe = File.join(BUILD_TOOLS_DIR, 'lib/OctopusTools/tools', 'Octo.exe')
  end

  def create_release(build_number, deployment_name)
    create_versioned_release(build_number, build_number, deployment_name)
  end

  def create_versioned_release(
    version_build_number, package_build_number, deployment_name, **octo_exe_args
  )
    puts "Created release #{version_build_number} for version #{package_build_number} of " \
        "#{deployment_name}..."

    additional_args =
      octo_exe_args
      .map do |key, value|
        "--#{key}=\"#{value}\""
      end
      .join(' ')

    create_specific_version = "--version=#{version_build_number}" unless version_build_number.nil?

    unless package_build_number.nil?
      create_package_version = "--packageversion=#{package_build_number}"
    end

    puts "#{@octo_exe} "\
        'create-release '\
        "--project=\"#{deployment_name}\" "\
        "#{create_specific_version} "\
        "#{create_package_version} "\
        '--waitfordeployment '\
        "--server=#{@octopus_deploy_server} "\
        '--apiKey=[PROTECTED] '\
        "#{additional_args} "

    system("#{@octo_exe} "\
        'create-release '\
        "--project=\"#{deployment_name}\" "\
        "#{create_specific_version} "\
        "#{create_package_version} "\
        '--waitfordeployment '\
        "--server=#{@octopus_deploy_server} "\
        "--apiKey=#{@api_key} "\
        "#{additional_args} ") || raise("octopus create-release failed #{version_build_number}")
  end

  def delete_release(build_number, deployment_name)
    puts "Deleted release #{build_number} of #{deployment_name}..."

    puts "#{@octo_exe} "\
        'delete-releases '\
        "--project=\"#{deployment_name}\" "\
        "--minversion=\"#{build_number}\" "\
        "--maxversion=\"#{build_number}\" "\
        "--server=#{@octopus_deploy_server} "\
        '--apiKey=[PROTECTED]'

    system("#{@octo_exe} "\
        'delete-releases '\
        "--project=\"#{deployment_name}\" "\
        "--minversion=\"#{build_number}\" "\
        "--maxversion=\"#{build_number}\" "\
        "--server=#{@octopus_deploy_server} "\
        "--apiKey=#{@api_key}") || raise("octopus delete-releases failed #{build_number}")
  end

  def delete_temporary_releases(machine_name, deployment_name)
    puts "Deleted releases for #{machine_name}..."

    puts "#{@octo_exe} "\
        'delete-releases '\
        "--project=\"#{deployment_name}\" "\
        "--minversion=\"0.0.0.0-#{machine_name}\" "\
        "--maxversion=\"0.99.0.0-#{machine_name}\" "\
        "--server=#{octopus_deploy_server} "\
        '--apiKey=[PROTECTED]'

    system("#{@octo_exe} "\
        'delete-releases '\
        "--project=\"#{deployment_name}\" "\
        "--minversion=\"0.0.0.0-#{machine_name}\" "\
        "--maxversion=\"0.99.0.0-#{machine_name}\" "\
        "--server=#{octopus_deploy_server} "\
        "--apiKey=#{api_key}") || raise("octopus delete-releases failed #{machine_name}")
  end

  def deploy_to_local(deployment_name, nuspec_file, nuget, steps_to_skip, **variables)
    this_machine_name = Socket.gethostname
    deploy_to(
      'Development Machines', this_machine_name, deployment_name, nuspec_file, nuget,
      steps_to_skip, variables
    )
  end

  def deploy_to(
    environment_name, target_machine_name, deployment_name, nuspec_file, nuget,
    steps_to_skip, **variables
  )
    build_machine_name = Socket.gethostname
    current_time = Time.now
    build_number = "0.#{current_time.day}.#{current_time.hour}#{current_time.min}." \
        "#{current_time.sec}"

    puts "Deploy #{build_number} of #{deployment_name} to #{target_machine_name}..."

    tasks(:build_release)[build_number.to_s]

    adhoc_build_number = "#{build_number}-#{build_machine_name}"

    begin
      delete_temporary_releases(
        build_machine_name, deployment_name, @octopus_deploy_server,
        @api_key
      )
    # TODO: rescue more specific error
    rescue StandardError
    end

    destination_folder = File.dirname(nuspec_file)
    destination_file = nuspec_file.sub '.nuspec', ".#{adhoc_build_number}.nupkg"
    nuget.create_package(adhoc_build_number, nuspec_file, destination_folder)
    nuget.push_package(destination_file)
    create_release(adhoc_build_number, deployment_name)
    deploy_release(
      deployment_name, adhoc_build_number, environment_name, target_machine_name,
      steps_to_skip, variables
    )

    FileUtils.rm(destination_file)
    adhoc_build_number
  end

  def deploy_release(
    deployment_name, release_number, environment_name, target_machine_name,
    steps_to_skip, **variables
  )
    prompt_variables =
      variables
      .map do |key, value|
        "--variable=#{key}:#{value}"
      end
      .join(' ')

    unless steps_to_skip.nil?
      skipping_steps =
        steps_to_skip
        .each
        .map do |step|
          "--skip \"#{step}\""
        end
        .join(' ')
    end

    unless target_machine_name.nil?
      target_specific_machines = "--specificmachines=#{target_machine_name}"
    end

    puts "#{@octo_exe} "\
        'deploy-release '\
        "--project=\"#{deployment_name}\" "\
        "--deployTo=\"#{environment_name}\" "\
        "--releaseNumber=#{release_number} "\
        "#{target_specific_machines} "\
        '--waitfordeployment '\
        '--deploymenttimeout=01:30:00 '\
        "--server=#{@octopus_deploy_server} "\
        '--apiKey=[PROTECTED] '\
        "#{skipping_steps} "\
        "#{prompt_variables}"

    system("#{@octo_exe} "\
        'deploy-release '\
        "--project=\"#{deployment_name}\" "\
        "--deployTo=\"#{environment_name}\" "\
        "--releaseNumber=#{release_number} "\
        "#{target_specific_machines} "\
        '--waitfordeployment '\
        '--deploymenttimeout=01:30:00 '\
        "--server=#{@octopus_deploy_server} "\
        "--apiKey=#{@api_key} "\
        "#{skipping_steps} "\
        "#{prompt_variables}") || raise("octopus deploy failed #{release_number}")
  end

  def export_project(deployment_name)
    filepath = "#{deployment_name}.json.tmp"

    puts "#{@octo_exe} "\
        'export '\
        '--type=project '\
        "--project=\"#{deployment_name}\" "\
        "--name=\"#{deployment_name}\" "\
        "--filePath=#{filepath} "\
        "--server=#{@octopus_deploy_server} "\
        '--apiKey=[PROTECTED]'

    system("#{@octo_exe} "\
        'export '\
        '--type=project '\
        "--project=\"#{deployment_name}\" "\
        "--name=\"#{deployment_name}\" "\
        "--filePath=#{filepath} "\
        "--server=#{@octopus_deploy_server} "\
        "--apiKey=#{@api_key}") || raise("octopus export failed #{deployment_name}")
    file = File.read(filepath)
    File.delete(filepath)
    JSON.parse(file)
  end

  def export_variables(deployment_name, environment = 'Environments-1')
    # Environments-1 = Development Machines
    # TODO: support friendly name lookups
    project = export_project(deployment_name)

    environment_variables = project['VariableSet']['Variables'].filter do |variable|
      variable['Scope']['Machine'].nil? && (
        variable['Scope']['Environment'].nil? || (
          variable['Scope']['Environment'].include? environment
        )
      )
    end

    environment_variables.sort do |a, b|
      # sort array by name and number of environment conditions that exist so that
      # dev scopes are higher than universal scopes
      [b['Name'], (b['Scope']['Environment'] || []).length] <=>
        [a['Name'], (a['Scope']['Environment'] || []).length]
    end
  end
end

class Octopus_Deploy < OctopusDeploy # rubocop:disable Naming/ClassAndModuleCamelCase
  def initialize(octopus_deploy_server, api_key)
    warn '[DEPRECATED] class Octopus_Deploy, use OctopusDeploy instead'
    super(octopus_deploy_server, api_key)
  end
end
