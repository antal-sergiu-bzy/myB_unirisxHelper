require_relative './powershell.rb'

class OctoReplace
  TEMP_VARIABLE_FILE = 'octostache_variables.json.tmp'.freeze

  def initialize(files, variables)
    @files = files
    @variables = variables
  end

  def replace
    create_json_file
    run_replace_script
    cleanup_json
  end

  def replace_config
    create_json_file
    run_replace_config_script
    cleanup_json
  end

  private

  def create_json_file
    @file_path = File.join(BUILD_TOOLS_DIR, TEMP_VARIABLE_FILE)
    File.open(@file_path, 'w') do |f|
      f.write(@variables.to_json)
    end
  end

  def run_replace_script
    @files.each do |file|
      ps = Powershell.new
      ps_args = [file, @file_path]
      ps.execute('.\RunOctostache.ps1', ps_args, BUILD_TOOLS_DIR)
    end
  end

  def run_replace_config_script
    @files.each do |file|
      ps = Powershell.new
      ps_args = [file, @file_path]
      ps.execute('.\RunCalamariConfigReplace.ps1', ps_args, BUILD_TOOLS_DIR)
    end
  end

  def cleanup_json
    File.delete(@file_path)
  end
end
