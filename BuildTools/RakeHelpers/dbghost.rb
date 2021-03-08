require 'albacore'
require 'openstruct'

module DBGhost
  def self.get_exe # rubocop:disable Naming/AccessorMethodName:
    warn '[DEPRECATED] DBGhost.get_exe, use DBGhost.executable instead'
    executable
  end

  def self.executable
    potential_exe_paths = ['', '(x86)'].map do |progfilessuffix|
      File.join(ENV["ProgramFiles#{progfilessuffix}"], 'DB Ghost', 'ChangeManagerCMD.exe')
    end
    dbg_exe = potential_exe_paths.filter do |exe|
      File.exist?(exe)
    end.first

    throw 'ChangeManagerCMD.exe not found!' unless dbg_exe
    dbg_exe
  end
end

def dbghost(*args)
  exec(*args) do |cmd, cmd_line_args|
    dbg_exe = DBGhost.get_exe

    dbgparams = OpenStruct.new
    yield dbgparams, cmd_line_args

    unless dbgparams.working_directory
      puts 'DANGER: working directory not specified for DBGhost!'.yellow
    end

    cmd.command = dbg_exe
    cmd.working_directory = dbgparams.working_directory
    cmd.parameters = [dbgparams.script.as_win_path, '/treatwarningsaserrors']

    cmd.parameters +=
      dbgparams
      .to_h
      .filter { |k| k.to_s.end_with?('server', 'database') }
      .map { |k, v| "/#{k} #{v}" }
  end
end
