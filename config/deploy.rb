# frozen_string_literal: true

set :application, "alexandria"

set :repo_url, "https://github.com/ucsblibrary/alexandria.git"
set :deploy_to, ENV.fetch("TARGET", "/opt/alexandria")

set :stages, %w[production vagrant]
set :default_stage, "vagrant"

set :log_level, :debug
set :bundle_flags, "--without=development test"
set :bundle_env_variables, nokogiri_use_system_libraries: 1

set :keep_releases, 2
set :passenger_restart_with_touch, true
set :assets_prefix, "#{shared_path}/public/assets"

set :linked_dirs, %w[
  tmp/pids
  tmp/cache
  tmp/sockets
  public/assets
  config/environments
]

# Default branch is :master
set :branch, ENV["REVISION"] || ENV["BRANCH_NAME"] || "master"

# Default value for :pty is false
# set :pty, true

set :linked_files, %w[
  config/secrets.yml
]

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

SSHKit.config.command_map[:rake] = "bundle exec rake"

require "resque"

set :resque_stderr_log, "#{shared_path}/log/resque-pool.stderr.log"
set :resque_stdout_log, "#{shared_path}/log/resque-pool.stdout.log"
set :resque_kill_signal, "QUIT"

namespace :deploy do
  before :restart, "resque:pool:stop"

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :clear_cache, "resque:pool:start"
end
