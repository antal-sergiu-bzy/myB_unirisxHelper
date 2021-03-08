# This module simplifies Docker daemon configuration
module DockerDaemon
  LOCAL = 'npipe://'.freeze
  LINUX = 'tcp://TK-DOCKER-LIN1.bfl.local:2375'.freeze
  WINDOWS = 'tcp://TK-DOCKER-WIN1.bfl.local:2375'.freeze
  TEST_SWARM = 'tcp://TK-SWARM-MANAG1.bfl.local:2375'.freeze
end

# This class describes a Docker registry (Artifactory for example)
class DockerRegistry
  attr_reader :name, :username, :password

  def initialize(args)
    @name = args[:name].downcase
    @username = args[:username]
    @password = args[:password]
  end

  # Provide standard / default Beazley registries
  NO_REGISTRY = DockerRegistry.new(
    name: '',
    username: '',
    password: ''
  )
  BEAZLEY_DOCKER_REGISTRY = DockerRegistry.new(
    name: 'artifactory.bfl.local/docker-beazleydocker-local'.freeze,
    username: ENV['DOCKER_REG_USERNAME'],
    password: ENV['DOCKER_REG_PASSWORD']
  )
  DOCKER_REGISTRY = DockerRegistry.new(
    name: 'docker.repo.bfl.local'.freeze,
    username: ENV['DOCKER_REG_USERNAME'],
    password: ENV['DOCKER_REG_PASSWORD']
  )
end

# This class descibes a Docker image
class DockerImage
  attr_reader :name, :dockerfile, :registry

  def initialize(args)
    @name = args[:name].downcase
    @dockerfile = args[:dockerfile]
    @registry = args[:registry]
  end
end
