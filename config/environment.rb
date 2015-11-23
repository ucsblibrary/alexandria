# Load the Rails application.
require File.expand_path('../application', __FILE__)

Rails.env = File.open('/vagrant/env').read.chomp

# Initialize the Rails application.
Rails.application.initialize!
