set :stage, :production
set :rails_env, 'production'

server ENV['SERVER'], user: 'deploy', roles: [:web, :app, :db]
set :ssh_options, port: 22, keys: ['~/.ssh/id_rsa']

set :linked_files,
    %w(
      config/application.rb
      config/blacklight.yml
      config/database.yml
      config/environment.rb
      config/environments/production.rb
      config/ezid.yml
      config/fedora.yml
      config/ldap.yml
      config/redis.yml
      config/resque-pool.yml
      config/secrets.yml
      config/smtp.yml
      config/solr.yml
    )
