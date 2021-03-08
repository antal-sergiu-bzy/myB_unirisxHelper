# VarFiles Module
module VarFiles
  @paths = []
  @variables = {}

  def self.paths
    @paths
  end

  def self.paths=(val)
    @paths = val
  end

  def self.add_path(val)
    @paths = @paths.concat(val)
  end
end
