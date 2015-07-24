require File.expand_path('../features/session_helper', __FILE__)

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :feature
  config.include Features::SessionHelper, type: :feature

  config.before(:each, type: :feature) do
    Warden.test_mode!
  end

  config.after(:each, type: :feature) do
    Warden.test_reset!
  end
end
