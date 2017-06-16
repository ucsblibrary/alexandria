# frozen_string_literal: true

set :stage, :internal_build
set :rails_env, "production"
set :branch, ENV["BRANCH"] || "master"
set :deploy_to, "/opt/alexandria"
server "localhost", user: "adrl", roles: [:web, :app, :db, :resque_pool]
