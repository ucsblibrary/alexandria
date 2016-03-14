set :stage, :production
set :rails_env, 'production'

server ENV['SERVER'], user: ENV.fetch('USER', 'adrl'), roles: [:web, :app, :db, :resque_pool]
set :ssh_options, port: 22, keys: [ENV.fetch('KEYFILE', '~/.ssh/id_rsa')]
