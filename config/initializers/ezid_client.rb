# frozen_string_literal: true

# Don't run ERB on the entire file, since in non-production contexts
# /opt/secret-server/secretserver-jconsole.jar probably won't exist so it will
# throw an error
def yaml_conf
  @yaml_conf ||= YAML.safe_load(
    File.read(Rails.root.join("config", "ezid.yml")),
    # by default #safe_load doesn't allow aliases
    # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
    [], [], true
  )[Rails.env]
end

Ezid::Client.configure do |config|
  config.default_shoulder = yaml_conf["shoulder"]
  config.logger           = Rails.logger
  config.password         = ERB.new(yaml_conf["password"]).result
  config.user             = ERB.new(yaml_conf["username"]).result
end
