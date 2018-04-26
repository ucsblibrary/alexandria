# frozen_string_literal: true

source "https://rubygems.org"

group :production do
  gem "pg", "~> 0.18.4"
end

gem "puma"
gem "rails", "~> 5.1.5"

gem "font-awesome-sass"
gem "jquery-rails", "~> 4.0"
gem "sass-rails", "~> 5.0"
gem "uglifier", "~> 3.1"

gem "jbuilder", "~> 2.0"
gem "therubyracer", "~> 0.12.3", platforms: :ruby

gem "active-triples", "~> 0.11.0"
gem "blacklight-gallery", "~> 0.8.0"
gem "blacklight_oai_provider"
gem "blacklight_range_limit"
gem "curation_concerns", "~> 1.7.7"
gem "ezid-client", "~> 1.2"
gem "hydra-role-management"
gem "linked_vocabs",
    git: "https://github.com/projecthydra-labs/linked_vocabs.git"
gem "marc"
gem "metadata_ci",
    git: "https://github.com/ucsblibrary/metadata-ci.git",
    ref: "018a7fb56abec9bbf229facaec711166b736f500"
gem "mods", "~> 2.0.3"
gem "openseadragon"
gem "qa", "~> 0.11.0"
gem "rdf-marmotta", "~> 0.1.1"
gem "riiif", ">= 2.0.0"
gem "rsolr"
gem "simple_form", "3.5.0"
gem "traject", "~> 2.3.2"

# https://github.com/amatsuda/kaminari/pull/636
gem "kaminari_route_prefix"

gem "net-ldap", "~> 0.14"
gem "settingslogic"

gem "resque-pool"
gem "resque-status"
gem "resque-web"

# for bin/ingest
gem "trollop"

# When parsing the ETD metadata file from ProQuest,
# some of the dates are American-style.
gem "american_date", "~> 1.1.0"

group :development, :test do
  gem "awesome_print"
  gem "byebug"
  gem "factory_bot_rails"

  # Used exact gem versions for solr_wrapper and fcrepo_wrapper
  # because they aren't careful about making breaking changes on
  # minor releases, so we'll need to be mindful about upgrading.
  gem "fcrepo_wrapper", "0.7.0"
  gem "solr_wrapper", "~> 0.19.0"

  gem "poltergeist"
  gem "rspec-activemodel-mocks"
  gem "rspec-rails"
  gem "rubocop", "~> 0.53", require: false
  gem "rubocop-rspec", require: false
  gem "spring"
  gem "spring-commands-rspec", group: :development
  gem "sqlite3"
end

group :test do
  gem "capybara"
  gem "ci_reporter"
  gem "database_cleaner"
  gem "rails-controller-testing"
  gem "timecop"
  gem "vcr"
  gem "webmock", require: false
end

group :development do
  gem "capistrano", "~> 3.8.0"
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "capistrano-rails", ">= 1.1.3"
  gem "highline"

  gem "http_logger"
  gem "method_source"
  gem "pry"
  gem "pry-doc"
end
