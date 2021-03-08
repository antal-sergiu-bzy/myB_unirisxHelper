# BeazleyTerraform
class BeazleyTerraform
  attr_accessor :module_path

  def initialize(path, module_path = '', global_vars = [])
    @path = path
    @module_path = module_path
    @global_vars = collect_multiple_tf_args(global_vars, 'var-file', '-[key]="[val]"')
  end

  def exec_terraform(command = 'init', arg = '', **args)
    require 'open3'
    require 'English'

    exec_cmd = "#{@path} #{command}"

    # Collect all flag options (keys)
    exec_cmd << collect_multiple_tf_args(args[:flags], 'var', '-[val]')

    # Ensure the module input is handled correctly as it isn't consistent across commands
    if include_module_path_as_arg(command)
      exec_cmd << collect_multiple_tf_args(@module_path, 'module', '-[key]="[val]"')
    elsif @module_path != ''
      # Set the arg to be the module path if it isn't empty
      arg = @module_path
    end

    # First merge in any generic var files that are present in build tools
    exec_cmd << @global_vars

    # Collect all -var-file options (key + value)
    exec_cmd << collect_multiple_tf_args(args[:var_file], 'var-file', '-[key]="[val]"')

    # Collect all -var options (key ('var=value'))
    exec_cmd << collect_multiple_tf_args(args[:vars])

    # Collect together all of the other key/value pairs
    exec_cmd << collect_multiple_tf_args(args[:options], nil, '-[key]="[val]"')

    exec_cmd << " #{arg}" unless arg.nil?

    puts exec_cmd

    # Capture output for use if needed from exec statement (tf_test uses output)
    out = ''
    IO.popen(exec_cmd).each do |l|
      out << l.chomp                    # collects output for use by caller
      puts l.chomp unless args[:silent] # streams output to stdout
    end

    out
  end

  # Returns true if the command run includes module arg as an option instead of arg
  def include_module_path_as_arg(command)
    %w[taint untaint].include?(command)
  end

  # Returns string separated values, replacing key value placeholders with actual values
  # based on input type
  def collect_multiple_tf_args(values, key = 'var', template = '-[key] "[val]"')
    return '' if values.nil? || values.empty?

    ' ' + values.each
                .map do |val|
                  if key.nil? # Supports generic k/v pairs
                    kv = val.split(':')
                    template.gsub('[key]', kv[0]).gsub('[val]', kv[1])
                  else
                    template.gsub('[key]', key).gsub('[val]', val)
                  end
                end
                .join(' ')
  end
end
