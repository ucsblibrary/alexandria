set :stage, :vagrant
set :rails_env, 'development'
set :bundle_without, [:test]

# change the value of `keys` if your GitHub key isn't id_rsa
set :ssh_options, port: 2222, keys: ['~/.ssh/id_rsa']
server ENV['SERVER'], user: 'deploy', roles: [:web, :app, :db]

# These files will be configured by the provisioning script in
# PASSENGER_APP_ROOT/shared/
set :linked_files, %w(config/resque-pool.yml config/redis.yml config/blacklight.yml config/database.yml config/ezid.yml config/fedora.yml config/ldap.yml config/secrets.yml config/smtp.yml config/solr.yml)
