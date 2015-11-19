# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'resque/tasks'
require 'resque/pool/tasks'

Rails.application.load_tasks
Jettywrapper.hydra_jetty_version = 'v8.4.0' if defined? Jettywrapper

# Get rid of the default task (was spec)
task default: []; Rake::Task[:default].clear

task default: :ci
