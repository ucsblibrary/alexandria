# frozen_string_literal: true

# Load DSL and set up stages
require "capistrano/setup"

# Include default deployment tasks
require "capistrano/deploy"

require "capistrano/bundler"
require "capistrano/rails"
require "capistrano/passenger"

# https://github.com/capistrano/capistrano/blob/v3.7.0/UPGRADING-3.7.md#the-scm-variable-is-deprecated
require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Load custom tasks from `lib/capistrano/tasks' if you have any defined
Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
