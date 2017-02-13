# frozen_string_literal: true
namespace :resque do
  task setup: :environment do
    Resque.after_fork do
      Resque.redis.client.reconnect
    end
  end
end
