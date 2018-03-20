# frozen_string_literal: true

set :stage, :sandbox
set :rails_env, "production"
server "128.111.87.17", user: "adrl", roles: [:web, :app, :db, :resque_pool]
