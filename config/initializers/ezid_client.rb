file = Rails.root.join('config/ezid.yml')
fail "You are missing a configuration file: #{file}." unless File.exist?(file)

begin
  yml = YAML.load_file(file)
rescue StandardError => e
  raise("#{file} was found, but could not be parsed.\n")
end

if yml.nil? || !yml.is_a?(Hash)
  fail("#{file} was found, but was blank or malformed.\n")
end

options = yml.fetch(Rails.env).with_indifferent_access

Ezid::Client.configure do |config|
  config.user             = options.fetch(:user)
  config.password         = options.fetch(:password)
  config.host             = options.fetch(:host)
  config.port             = options.fetch(:port)
  config.use_ssl          = (options.fetch(:port) != 80)
  config.default_shoulder = options.fetch(:default_shoulder)
  config.logger           = Rails.logger
end
