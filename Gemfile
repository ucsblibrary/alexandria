# frozen_string_literal: true

source "https://rubygems.org"

gem "active-triples"
gem "american_date"
gem "blacklight-gallery"
gem "blacklight_range_limit"
gem "coffee-rails"
gem "ezid-client"
gem "font-awesome-sass"
gem "hydra-role-management"
gem "jbuilder"
gem "jquery-rails"
gem "kaminari_route_prefix"
gem "marc"
gem "mods"
gem "net-ldap"
gem "openseadragon"
gem "puma"
gem "rails", "~> 5.1.3"
gem "rdf-marmotta"
gem "resque-pool"
gem "resque-status"
gem "rsolr"
gem "sass-rails"
gem "settingslogic"
gem "traject"
gem "trollop"
gem "uglifier"

gem "hyrax", path: "/home/cat/clones/hyrax"
gem "linked_vocabs",
    git: "https://github.com/projecthydra-labs/linked_vocabs.git"
gem "metadata_ci",
    git: "https://github.com/ucsblibrary/metadata-ci.git",
    ref: "c127d0d84d5de213b828be2b25b0e38db365fb5a"
gem "riiif",
    git: "https://github.com/curationexperts/riiif.git",
    ref: "3cab3a2b8b54e76b74b73f18637211f76dc66b92"

group :production do
  gem "pg", "~> 0.18.4"
end

group :development, :test do
  gem "byebug"
  gem "factory_bot_rails"

  gem "fcrepo_wrapper"
  gem "method_source"
  gem "poltergeist"
  gem "pry"
  gem "pry-doc"
  gem "rspec-activemodel-mocks"
  gem "rspec-rails"
  gem "rubocop", "~> 0.49.0", require: false
  gem "rubocop-rspec", require: false
  gem "selenium-webdriver"
  gem "solr_wrapper"
  gem "spring"
  gem "spring-commands-rspec"
  gem "sqlite3"
end

group :test do
  gem "capybara"
  gem "database_cleaner"
  gem "rails-controller-testing"
  gem "timecop"
  gem "vcr"
  gem "webmock", require: false
end

group :development do
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "highline"
  gem "http_logger"
end
