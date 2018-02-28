# frozen_string_literal: true

set :stage, :sandbox
set :rails_env, "production"
set :repo_url, "https://github.com/ucsblibrary/alexandria.git"
server "128.111.87.107", user: "adrl", roles: [:web, :app, :db]
