# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'alex2'
set :scm, :git
set :repo_url, Pathname.new('/vagrant')
set :deploy_to, '/opt/alex2'

set :stages, %w(production vagrant)
set :default_stage, 'vagrant'

set :log_level, :debug
set :keep_releases, 5
set :passenger_restart_with_touch, true
set :assets_prefix, "#{shared_path}/public/assets"

set :linked_dirs, %w(tmp/pids tmp/cache tmp/sockets public/assets)

SSHKit.config.command_map[:rake] = 'bundle exec rake'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

require 'resque'

set :resque_stderr_log, "#{shared_path}/log/resque-pool.stderr.log"
set :resque_stdout_log, "#{shared_path}/log/resque-pool.stdout.log"
set :resque_kill_signal, 'QUIT'

namespace :deploy do
  before :restart, 'resque:pool:stop'

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :clear_cache, 'resque:pool:start'
end
