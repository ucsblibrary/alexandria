set :stage, :vagrant
set :rails_env, 'development'
set :bundle_without, [:test]

# change the value of `keys` if your GitHub key isn't id_rsa
set :ssh_options, port: 2222, keys: ['~/.ssh/id_rsa']
server ENV['SERVER'], user: 'deploy', roles: [:web, :app, :db]
