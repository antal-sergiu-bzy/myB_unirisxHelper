class Proj
  attr_reader :name, :type, :path, :stage_name

  def initialize(args)
    @name = args[:name]
    @type = args[:type]
    @path = args[:path]
    @stage_name = args[:stage_name].nil? ? @name : args[:stage_name]
  end
end
