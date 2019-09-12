# frozen_string_literal: true

require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Alexandria; end

# Settings in config/environments/* take precedence over those
# specified here.  Application configuration should go into files in
# config/initializers -- all .rb files in that directory are
# automatically loaded.
class Alexandria::Application < Rails::Application
  config.generators do |g|
    g.test_framework :rspec, spec: true
  end

  config.merritt_user     = "tjohnson"
  config.merritt_pwd = "8t8cOKR2YX"

  config.autoload_paths << Rails.root.join("lib")

  # Handle exceptions manually
  config.exceptions_app = routes

  config.action_mailer.smtp_settings =
    YAML.safe_load(
      File.read(Rails.root.join("config", "smtp.yml")),
      # by default #safe_load doesn't allow aliases
      # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
      [], [], true
    )[Rails.env] || {}

  # Set the backend for running background jobs
  #
  # FIXME: currently cylinders fail with :inline and :async
  config.active_job.queue_adapter = ENV["RAILS_QUEUE"]&.to_sym || :resque
end
