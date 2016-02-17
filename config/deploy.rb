# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'alexandria-v2'
set :scm, :git
set :repo_url, ENV.fetch('REPO', 'https://github.com/curationexperts/alexandria-v2.git')
set :deploy_to, '/opt/alexandria-v2'

set :stages, %w(production vagrant)
set :default_stage, 'vagrant'

set :log_level, :debug
set :bundle_flags, '--deployment'
set :bundle_env_variables, nokogiri_use_system_libraries: 1

set :keep_releases, 5
set :passenger_restart_with_touch, true
set :assets_prefix, "#{shared_path}/public/assets"

set :linked_dirs, %w(
  tmp/pids
  tmp/cache
  tmp/sockets
  public/assets
  config/environments
)

SSHKit.config.command_map[:rake] = 'bundle exec rake'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :pty is false
# set :pty, true

set :linked_files,
    %w(
      config/application.yml
      config/blacklight.yml
      config/database.yml
      config/fedora.yml
      config/ldap.yml
      config/redis.yml
      config/resque-pool.yml
      config/secrets.yml
      config/smtp.yml
      config/solr.yml
    )

# Default value for linked_dirs is []
# set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

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
