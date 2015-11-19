config = YAML.load(ERB.new(IO.read(File.join(Rails.root, 'config', 'redis.yml'))).result)[Rails.env].with_indifferent_access
Resque.redis = Redis.new(host: config[:host], port: config[:port], thread_safe: true)

Resque::Plugins::Status::Hash.expire_in = (14 * 24 * 60 * 60) # Delete statuses after 2 weeks
