require 'json'

class SecretServer
  def initialize(username, password, **args)
    @username = username
    @password = password
    @script = File.join(BUILD_TOOLS_DIR, 'GetSecretFromSecretServer.ps1')
    import_from_config_file(args[:secret_file])
  end

  def get_secret(secret_id)
    warn '[DEPRECATED] SecretServer::get_secret, use SecretServer::secret instead'
    secret(secret_id)
  end

  def secret(secret_id)
    # TODO: remove dependency on PS and implement in ruby natively
    command_line = "powershell.exe -NoProfile #{@script} -username #{@username} -password " \
        "#{@password} -secretId #{secret_id}"
    `#{command_line}`.strip
  end

  def set_secrets_as_env_vars(secret_ids) # rubocop:disable Naming/AccessorMethodName
    secret_ids.each do |k, v|
      ENV[k] = secret(v)
      puts "Env Var #{k} set with secret #{v}"
    end
  end

  def import_from_config_file(secret_file)
    return if secret_file.nil?
    return puts "The file #{secret_file} does not exist" unless File.exist?(secret_file)

    file = File.open(secret_file)
    set_secrets_as_env_vars(JSON.parse(file.read))
  end
end

class Secret_Server < SecretServer # rubocop:disable Naming/ClassAndModuleCamelCase
  def initialize(username, password, **args)
    warn '[DEPRECATED] class Secret_Server, use SecretServer instead'
    super(username, password, **args)
  end
end
