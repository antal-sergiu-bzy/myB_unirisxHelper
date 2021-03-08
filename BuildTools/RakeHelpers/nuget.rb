class Nuget
  def initialize(nuget_server, api_key)
    @nuget_server = nuget_server
    @api_key = api_key
  end

  def create_package(build_number, nuspec_file, destination_path,
                     properties: nil, nuget_arguments: nil)

    puts "Building NuGet Package from #{nuspec_file} version #{build_number} to " \
      "#{destination_path}..."

    all_nuget_args = [
      'pack', nuspec_file,
      '-NoPackageAnalysis',
      '-Version', build_number,
      '-OutputDirectory', destination_path,
      '-Properties', props(properties)
    ]
    all_nuget_args += nuget_arguments if nuget_arguments

    system(File.join(BUILD_TOOLS_DIR, 'NuGet.exe'), *all_nuget_args) \
      || raise("nuget pack failed for #{nuspec_file} #{build_number}")
  end

  def push_package(nupkg_file)
    puts "Published NuGet package #{nupkg_file} to #{@nuget_server}..."

    system "#{File.join(BUILD_TOOLS_DIR, 'NuGet.exe')} "\
    "push \"#{nupkg_file}\" "\
    "-ApiKey #{@api_key} "\
    "-Source #{@nuget_server}"
  end

  def props(additional_properties)
    properties = { Configuration: 'Release' }
    # merge! will overwrite values with identical keys, allowing overriding of 'Configuration'
    properties.merge!(additional_properties) if additional_properties
    properties.keys.map { |key| "#{key}=#{properties[key]}" }.join(';')
  end
end

class PackageInformation
  attr_reader :name, :artifact_store, :source, :output_folder

  def initialize(args)
    @name = args[:name]
    @artifact_store = args[:artifact_store]

    # obsolete: should provide source_spec_dir and file derived from name
    @source = args[:source]

    unless args[:source_spec_dir].nil?
      @source = File.join(args[:source_spec_dir], "#{args[:name]}.nuspec")
    end

    @output_folder = args[:output_folder]

    return unless args[:options]

    nuget_exe_args << '-IncludeReferencedProjects' if args[:options][:include_referenced_projects]
  end

  def nuget_exe_args
    @nuget_exe_args ||= []
  end
end

class Package_Information < PackageInformation # rubocop:disable Naming/ClassAndModuleCamelCase
  def initialize(args)
    warn '[DEPRECATED] class Package_Information, use PackageInformation instead'
    super(args)
  end
end

class DeployInformation
  attr_reader :name, :deployer, :source, :artifact_store, :release_number

  def initialize(args)
    @deployer = args[:deployer]

    unless args[:package].nil?
      @source = args[:package].source
      @artifact_store = args[:package].artifact_store
      @name = args[:package].name
    end

    @name = args[:name] unless args[:name].nil?
    unless args[:source].nil?
      warn '[DEPRECATED] nuget.rb::Deploy_Information::initialize: "source" argument'
      warn '[DEPRECATED] use `package` argument instead as this value will be derived'
      @source = args[:source]
    end
    unless args[:artifact_store].nil?
      warn '[DEPRECATED] nuget.rb::Deploy_Information::initialize: "artifact_store" argument'
      warn '[DEPRECATED] use `package` argument instead as this value will be derived'
      @artifact_store = args[:artifact_store]
    end
    @release_number = args[:release_number]
  end
end

class Deploy_Information < DeployInformation # rubocop:disable Naming/ClassAndModuleCamelCase
  def initialize(args)
    warn '[DEPRECATED] class Deploy_Information, use DeployInformation instead'
    super(args)
  end
end
