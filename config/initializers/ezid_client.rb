# frozen_string_literal: true

Ezid::Client.configure do |config|
  config.default_shoulder = Rails.application.secrets.ezid_default_shoulder
  config.logger           = Rails.logger
  config.password         = Rails.application.secrets.ezid_pass
  config.user             = Rails.application.secrets.ezid_user
end
