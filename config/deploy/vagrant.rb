set :stage, :vagrant
set :rails_env, 'production'
set :bundle_without, [:development, :test]

# change the value of `keys` if your GitHub key isn't id_rsa
set :ssh_options, port: 2222, keys: ['~/.ssh/id_rsa']
server ENV['HOSTNAME'], user: 'adrl', roles: [:web, :app, :db]
