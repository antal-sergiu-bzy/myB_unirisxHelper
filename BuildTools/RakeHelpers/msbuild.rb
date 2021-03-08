def apply_build_defaults_to(msbuild)
  msbuild.log_level = :verbose
  msbuild.max_cpu_count = 4
end

# What's going on here?
#
# Normally when using `prepend` for monkey patching, you would just prepend a
# module with method(s) in it. However, in this case, we need to use the same
# `get_net_version` method to set the default (pinned) version of msbuild.
#
# By creating a nested module, we can not only prepend our overridden method to
# the MSBuild class so it gets picked up with any new instances, we can also
# `extend` the existing Configuration::MSBuild.msbuildconfig instance so we can
# utilize our overridden method to set the default value.
#
module MSBuildExtensions
  module ClassMethods
    def get_net_version(version)
      if version.respond_to?(:zero?)
        # https://ruby-doc.org/core-2.2.0/Kernel.html#method-i-sprintf
        # converts e.g. 12 to 12.0
        formatted_version = format('%0.1f', version)
        if version >= 12 && version < 15
          File.join(ENV['ProgramFiles(x86)'], 'MSBuild', formatted_version, 'bin')
        elsif version == 15
          msbuild_15_path = File.join(
            ENV['ProgramFiles(x86)'], 'Microsoft Visual Studio',
            '2017', '*', 'MSBuild', '15.0', 'bin'
          )
          Dir.glob msbuild_15_path.tr('\\', '/')
        else
          super("net#{formatted_version.sub('.', '')}".to_sym)
        end
      else
        super(version)
      end
    end
  end

  def self.included(mod)
    mod.prepend ClassMethods
    # extend existing instance
    Configuration::MSBuild.msbuildconfig.extend(ClassMethods)
    # pin to 12.0
    Configuration::MSBuild.msbuildconfig.use(14.0)
  end
end

class MSBuild
  include MSBuildExtensions
end
