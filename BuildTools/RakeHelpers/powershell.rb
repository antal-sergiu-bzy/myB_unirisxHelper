require 'albacore'
require 'json'

def powershell(*args)
  exec(*args) do |cmd, cmd_line_args|
    ps_cmd_args = OpenStruct.new
    yield ps_cmd_args, cmd_line_args
    cmd.command = 'powershell.exe'
    ps_args = ps_cmd_args.parameters.nil? ? '' : " #{ps_cmd_args.parameters.join(' ')}"
    cmd.parameters = [
      '-nologo',
      '-noprofile',
      '-executionpolicy bypass',
      "-command \"& '#{ps_cmd_args.command}'#{ps_args}\""
    ]
    if defined? ps_cmd_args.version
      puts "Executing ps under #{ps_cmd_args.version}".yellow
      cmd.parameters << "-version '#{ps_cmd_args.version}'"
    end
    cmd.working_directory = ps_cmd_args.working_directory unless ps_cmd_args.working_directory.nil?
  end
end

class Powershell
  def execute(command, args = nil, working_directory = nil)
    exec = Exec.new
    exec.command = 'powershell.exe'
    ps_args = args.nil? ? '' : " #{args.join(' ')}"
    exec.parameters = [
      '-nologo',
      '-noprofile',
      '-executionpolicy bypass',
      "-command \"& '#{command}'#{ps_args}\""
    ]

    exec.working_directory = working_directory unless working_directory.nil?
    puts exec.working_directory
    exec.execute
  end
end
