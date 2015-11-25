set :stage, :production
set :rails_env, 'production'

server ENV['SERVER'], user: 'deploy', roles: [:web, :app, :db]
set :ssh_options, port: 22, keys: ['~/.ssh/id_rsa']

set :linked_files, %w(config/resque-pool.yml config/redis.yml config/blacklight.yml config/database.yml config/ezid.yml config/fedora.yml config/ldap.yml config/secrets.yml config/smtp.yml config/solr.yml config/environments/production.rb)
