# frozen_string_literal: true

def ezid_yaml_conf
  @ezid_yaml_conf ||= YAML.safe_load(
    ERB.new(File.read(Rails.root.join("config", "ezid.yml"))).result,
    # by default #safe_load doesn't allow aliases
    # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
    [], [], true
  )[Rails.env]
end

Ezid::Client.configure do |config|
  config.default_shoulder = ezid_yaml_conf["shoulder"]
  config.logger           = Rails.logger
  config.password         = ezid_yaml_conf["password"]
  config.user             = ezid_yaml_conf["username"]
end
