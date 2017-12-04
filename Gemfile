# frozen_string_literal: true

source "https://rubygems.org"

group :production do
  gem "pg", "~> 0.18.4"
end

gem "puma"
gem "rails", "~> 5.1.1"

gem "font-awesome-sass"
gem "jquery-rails"
gem "sass-rails"
gem "uglifier"

gem "jbuilder", "~> 2.0"
gem "therubyracer", "~> 0.12.3", platforms: :ruby

gem "active-triples"
gem "blacklight-gallery"
gem "blacklight_range_limit"
gem "curation_concerns", "~> 1.7.7"
gem "ezid-client"
gem "hydra-role-management"
gem "linked_vocabs",
    git: "https://github.com/projecthydra-labs/linked_vocabs.git"
gem "marc"
gem "metadata_ci",
    git: "https://github.com/ucsblibrary/metadata-ci.git",
    ref: "c127d0d84d5de213b828be2b25b0e38db365fb5a"
gem "mods"
gem "openseadragon"
gem "rdf-marmotta"
gem "riiif",
    git: "https://github.com/curationexperts/riiif.git",
    ref: "db122f9f61c2573c620a8d6ac39bd7633149da45"
gem "rsolr"
gem "traject"

# https://github.com/amatsuda/kaminari/pull/636
gem "kaminari_route_prefix"

gem "net-ldap"
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

  gem "fcrepo_wrapper"
  gem "solr_wrapper"

  gem "poltergeist"
  gem "rspec-activemodel-mocks"
  gem "rspec-rails"
  gem "rubocop", "~> 0.49.0", require: false
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
  gem "capistrano"
  gem "capistrano-bundler"
  gem "capistrano-passenger"
  gem "capistrano-rails"
  gem "highline"

  gem "http_logger"
  gem "method_source"
  gem "pry"
  gem "pry-doc"
end
