# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require "spec_helper"
require File.expand_path("../../config/environment", __FILE__)

require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!

require "capybara/rails"
require "capybara/poltergeist"
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false)
end
Capybara.javascript_driver = :poltergeist

# HttpLogger.logger = Logger.new(STDOUT)
# HttpLogger.ignore = [/\/solr/, /\/marmotta/]
# HttpLogger.colorize = true
# HttpLogger.log_headers = false

require "webmock"
WebMock.enable!
WebMock.disable_net_connect!(allow_localhost: true)
# WebMock.allow_net_connect!

VCR.configure do |config|
  config.ignore_hosts "127.0.0.1", "localhost"
  config.cassette_library_dir = "spec/fixtures/vcr"
  config.hook_into :webmock
end

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

require "active_fedora/cleaner"

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before :suite do
    DatabaseCleaner.clean_with(:truncation)
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists
  end

  config.before do
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
                                 :transaction
                               else
                                 :truncation
                               end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.infer_spec_type_from_file_location!

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input
  config.include FactoryBot::Syntax::Methods
  config.include CollectionSupport, type: :feature
  config.include FixtureFileUpload
end

def user_with_groups(groups)
  User.create(group_list: groups)
end
