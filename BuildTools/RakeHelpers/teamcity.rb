module TeamCity
  def self.set_version(version) # rubocop:disable Naming/AccessorMethodName
    warn '[DEPRECATED] TeamCity.set_version, use \'TeamCity.version =\' instead'
    self.version = version
  end

  def self.version=(version)
    puts "##teamcity[buildNumber '#{version}']" if running_on_agent?
  end

  def self.running_on_agent?
    !ENV['TEAMCITY_VERSION'].nil?
  end
end
