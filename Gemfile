# frozen_string_literal: true
source "https://rubygems.org"

group :production, :development do
  gem "pg", "~> 0.18.4"
end

gem "rails", "4.2.8"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"

gem "uglifier", "~> 2.7.2"
gem "jquery-rails", "~> 4.0.5"

gem "jbuilder", "~> 2.0"
gem "therubyracer", platforms: :ruby

gem "blacklight-gallery", "~> 0.5.0"
gem "blacklight_range_limit", "~> 6.0.0"
gem "curation_concerns", "1.6.3"
gem "ezid-client", "~> 1.2"
gem "hydra-role-management"
gem "linked_vocabs", "~> 0.3.1"
gem "marc"
gem "mods", "~> 2.0.3"
gem "qa", "~> 0.5.0"
gem "rdf-marmotta", "~> 0.0.8"
gem "riiif", "~> 0.4.0"
gem "rsolr", "~> 1.0.12"
gem "traject", "~> 2.3.2"

gem "kaminari", "~> 0.16.3"
# https://github.com/amatsuda/kaminari/pull/636
gem "kaminari_route_prefix"

gem "devise", "~> 3.5.2"
gem "devise_ldap_authenticatable"
gem "devise-guests", "~> 0.5.0"
gem "settingslogic"

gem "resque-status"
gem "resque-pool"

# for bin/ingest
gem "trollop"

# When parsing the ETD metadata file from ProQuest,
# some of the dates are American-style.
gem "american_date", "~> 1.1.0"

group :development, :test do
  gem "awesome_print"
  gem "byebug"
  gem "factory_girl_rails", "~> 4.4"

  # Used exact gem versions for solr_wrapper and fcrepo_wrapper
  # because they aren't careful about making breaking changes on
  # minor releases, so we'll need to be mindful about upgrading.
  gem "fcrepo_wrapper", "0.7.0"
  gem "solr_wrapper", "~> 0.19.0"

  gem "poltergeist"
  gem "rspec-activemodel-mocks"
  gem "rspec-rails"
  gem "rubocop", "~> 0.47.1", require: false
  gem "spring"
  gem "spring-commands-rspec", group: :development
end

group :test do
  gem "capybara", "2.6.2"
  gem "ci_reporter"
  gem "database_cleaner"
  gem "sqlite3"
  gem "timecop", "0.7.3"
  gem "vcr"
  gem "webmock", require: false
end

group :development do
  gem "capistrano", "3.7.0"
  gem "capistrano-rails", ">= 1.1.3"
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "highline"

  gem "method_source"
  gem "pry"
  gem "pry-doc"
end
