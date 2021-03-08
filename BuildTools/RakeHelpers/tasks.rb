def tasks(task_name)
  warn '[DEPRECATED] method \'tasks(:task_name)[args]\' use task(:task_name).invoke(args) instead'
  task = Rake::Task[task_name]
  ->(*args) { task.invoke(*args) }
end
