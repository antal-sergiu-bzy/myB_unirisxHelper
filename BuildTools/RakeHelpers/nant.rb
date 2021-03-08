require 'albacore'
require 'ostruct'

# the intent of this is to keep a very similar format to creating an Albacore
# `nant` task but this will create tasks for all tasks in nant build file
def generate_tasks_from_nant(*args)
  opts = OpenStruct.new
  yield opts
  # use nant.exe on PATH if not provided
  opts.command ||= 'nant.exe'
  # nant can auto-discover the buildfile so don't require it
  build_file_arg = " -buildfile:#{opts.build_file}" if opts.build_file

  nant_tasks = `#{opts.command}#{build_file_arg} -projecthelp -nologo`
               .split("\n")
               .map(&:strip) # remove whitespace
               .filter { |s| s =~ /^[A-Za-z0-9\-._]+$/ } # only grab task names
               .uniq

  nant_tasks.each do |nant_task_name|
    # convert special characters to underscore so we can create symbols
    santized_task_name = nant_task_name.gsub(/[.\-]/, '_')
    # create an Albacore `nant` task with 'nant_' (or opts.prefix) prefix
    task_name = "#{opts.prefix || 'nant_'}#{santized_task_name}"
    nant task_name.to_sym, *args do |nant|
      yield nant
      nant.command ||= opts.command
      nant.targets = [nant_task_name]
    end
  end
end
