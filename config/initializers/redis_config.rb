# frozen_string_literal: true

config = YAML.safe_load(
  ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result,
  # by default #safe_load doesn't allow aliases
  # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
  [], [], true
)[Rails.env].with_indifferent_access

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # We're in smart spawning mode.
    if forked
      # Re-establish redis connection
      require "redis"

      # The important two lines
      $redis.client.disconnect if $redis
      $redis = begin
                 Redis.new(host: config[:host], port: config[:port], thread_safe: true)
               rescue
                 nil
               end
      Resque.redis = $redis
      Resque.redis.namespace = "curation_concerns:#{Rails.env}"
      Resque.redis.client.reconnect if Resque.redis
    end
  end
else
  $redis = begin
             Redis.new(host: config[:host], port: config[:port], thread_safe: true)
           rescue
             nil
           end
end
