# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'alexandria-v2'
set :scm, :git
set :repo_url, 'https://github.com/curationexperts/alexandria-v2.git'
#set :branch, 'master'
set :deploy_to, '/opt/alex2'
set :log_level, :debug
set :keep_releases, 5
set :passenger_restart_with_touch, true

set :assets_prefix, "#{shared_path}/public/assets"

set :linked_files, %w{config/resque-pool.yml config/redis.yml config/blacklight.yml config/database.yml config/ezid.yml config/fedora.yml config/ldap.yml config/secrets.yml config/smtp.yml config/solr.yml config/environments/production.rb}

set :linked_dirs, %w{tmp/pids tmp/cache tmp/sockets public/assets}

set :resque_stderr_log, "#{shared_path}/log/resque-pool.stderr.log"
set :resque_stdout_log, "#{shared_path}/log/resque-pool.stdout.log"
set :resque_kill_signal, "QUIT"

SSHKit.config.command_map[:rake] = "bundle exec rake"

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

require "resque"

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
