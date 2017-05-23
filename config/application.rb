# frozen_string_literal: true

require_relative "boot"
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Alexandria
  # Settings in config/environments/* take precedence over those
  # specified here.  Application configuration should go into files in
  # config/initializers -- all .rb files in that directory are
  # automatically loaded.
  class Application < Rails::Application
    config.generators do |g|
      g.test_framework :rspec, spec: true
    end

    # Handle exceptions manually
    config.exceptions_app = routes

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.action_mailer.smtp_settings =
      YAML.safe_load(
        File.read(Rails.root.join("config", "smtp.yml")),
        # by default #safe_load doesn't allow aliases
        # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
        [], [], true
      )[Rails.env] || {}

    # Set the backend for running background jobs
    config.active_job.queue_adapter = :resque
    # Should make Resque clean up tempfiles more aggressively
    # https://groups.google.com/d/msg/hydra-tech/muk1eLjycXE/m0ejQl1lCAAJ
    # https://github.com/resque/resque/blob/105a54017fe2eb12cb09fa3241afce06581cf586/HISTORY.md#1240-2013-3-21p
    config.before_configuration { ENV["RUN_AT_EXIT_HOOKS"] = "1" }
  end
end
