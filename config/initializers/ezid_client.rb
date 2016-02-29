file = Rails.root.join('config/application.yml')
raise "You are missing a configuration file: #{file}." unless File.exist?(file)

begin
  yml = YAML.load_file(file)
rescue StandardError
  raise("#{file} was found, but could not be parsed.\n")
end

if yml.nil? || !yml.is_a?(Hash)
  raise("#{file} was found, but was blank or malformed.\n")
end

options = yml.fetch(Rails.env).with_indifferent_access

Ezid::Client.configure do |config|
  config.user             = Rails.application.secrets.ezid_user
  config.password         = Rails.application.secrets.ezid_pass
  config.host             = options.fetch(:ezid_host)
  config.port             = options.fetch(:ezid_port)
  config.use_ssl          = (options.fetch(:ezid_port) != 80)
  config.default_shoulder = Rails.application.secrets.ezid_default_shoulder
  config.logger           = Rails.logger
end
