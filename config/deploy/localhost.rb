# frozen_string_literal: true

set :rails_env, "production"
server "localhost", user: "deploy", roles: [:web, :app, :db, :resque_pool]
