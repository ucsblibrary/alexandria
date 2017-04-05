# frozen_string_literal: true

require "resque"
config = YAML.safe_load(
  ERB.new(IO.read(Rails.root.join("config", "redis.yml"))).result,
  # by default #safe_load doesn't allow aliases
  # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
  [], [], true
)[Rails.env].with_indifferent_access

Resque.redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true)
Resque.inline = Rails.env.test?
Resque.redis.namespace = "curation_concerns:#{Rails.env}"
