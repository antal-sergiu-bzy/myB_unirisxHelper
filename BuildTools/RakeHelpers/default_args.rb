# this allows adding an action to run before existing task actions
module Rake
  class Task
    def preexecute(&block)
      @actions.unshift(block)
    end
  end
end

# set arg defaults on all tasks to avoid
# calling with_defaults in every task
def set_default_args(defaults) # rubocop:disable Naming/AccessorMethodName
  warn '[DEPRECATED] set_default_args, use \'self.default_args =\' instead'
  self.default_args = defaults
end

def default_args=(defaults)
  Rake::Task.tasks.each do |t|
    t.preexecute do |_, args|
      args.with_defaults(defaults)
    end
  end
end
