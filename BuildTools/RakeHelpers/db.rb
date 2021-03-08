require 'fileutils'
require 'find'

def db_server(args)
  args.port_number && !args.port_number.empty? ? "#{args.server},#{args.port_number}" : args.server
end

class DatabaseHelper
  def register_sql_server_alias(cpu_architecture, alias_name, server)
    puts "Registered SQL Server alias (#{cpu_architecture}) #{alias_name} => #{server}"

    registry_path =
      if cpu_architecture == 'x64'
        'HKLM\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
      else
        'HKLM\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'
      end

    system "REG ADD #{registry_path} /v #{alias_name} /t REG_SZ /d ""DBMSSOCN,#{server}"''
  end

  def generate_generic_db_deploy_structure(database_source_folder, database_output_folder)
    # ScheMaster takes a config JSON file and output SQL file
    config_file = File.join(database_source_folder, 'SchemaGenConfig.json')
    sql_file = File.join(database_output_folder, 'Model', 'CreateSchema.sql')

    system "#{File.join(BUILD_TOOLS_DIR, 'ScheMaster.Generator', 'ScheMaster.Generator.exe')} "\
            "/config:\"#{config_file}\" "\
            "/sql:\"#{sql_file}\""

    # Copy utility files (except special DBGhostCustomScripts folder which is used further down)
    Find.find(database_source_folder) do |source|
      target = source.sub(/^#{database_source_folder}/, database_output_folder)
      if File.directory? source
        Find.prune if File.basename(source) == 'DBGhostCustomScripts'
        FileUtils.mkdir target unless File.exist? target
      else
        FileUtils.copy source, target
      end
    end

    # Copy the generic DB deploy files
    FileUtils.copy_entry(
      File.join(BUILD_TOOLS_DIR, 'db-generic-deploy'),
      File.join(database_output_folder, 'Scripts')
    )

    # Replace pre and post process scripts
    bespoke_db_ghost_scripts = File.join(database_source_folder, 'DBGhostCustomScripts')

    return unless File.directory?(bespoke_db_ghost_scripts)

    FileUtils.copy_entry(
      bespoke_db_ghost_scripts,
      File.join(database_output_folder, 'Scripts', 'DBGhostCustomScripts')
    )
  end
end

class DatabaseInformation
  attr_reader :name, :source, :schema

  def initialize(args)
    @name = args[:name]
    @source = args[:source]
    @schema = args[:schema]
  end
end

class Database_Information < DatabaseInformation # rubocop:disable Naming/ClassAndModuleCamelCase
  def initialize(args)
    warn '[DEPRECATED] class Database_Information, use DatabaseInformation instead'
    super(args)
  end
end
