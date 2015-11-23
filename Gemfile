source 'https://rubygems.org'

gem 'rails', '4.2.4'
gem 'pg', '0.18.3'

gem 'uglifier', '~> 2.7.2'
gem 'jquery-rails', '~> 4.0.5'
gem 'sass-rails', '~> 5.0'

gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'therubyracer', platforms: :ruby

gem 'hydra-head', '9.5.0'

# Optimise for a faster import: https://github.com/projecthydra/active_fedora/pull/876
gem 'active-fedora', github: 'projecthydra/active_fedora', ref: 'fec345a'

# https://github.com/ActiveTriples/ActiveTriples/pull/164
gem 'active-triples', github: 'ActiveTriples/ActiveTriples', ref: '71ed53a'
gem 'hydra-editor', '~> 1.0.4'
gem 'hydra-role-management'
gem 'hydra-collections', '~> 5.0.1'
gem 'rdf-marmotta', '~> 0.0.8'
gem 'rdf-vocab', '~> 0.8.4'

gem 'blacklight', '~> 5.16.0'
gem 'settingslogic'

gem 'rsolr', '~> 1.0.12'
# Needs 0.4.0
gem 'activefedora-aggregation', '~> 0.4.0'

gem 'mods', '~> 2.0.3'
gem 'oargun', github: 'curationexperts/oargun', ref: 'e303100'
gem 'linked_vocabs', github: 'jcoyne/linked_vocabs', branch: 'with_0.7_validation'
gem 'blacklight-gallery'
gem 'riiif', '~> 0.1.0'
gem 'ezid-client', '~> 1.0'
gem 'qa', '~> 0.5.0'

gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'

gem 'devise', '~> 3.5.2'
gem 'devise_ldap_authenticatable'
gem 'devise-guests', github: 'cbeer/devise-guests'

# see https://github.com/traject/traject/commit/656a992c400a472bf5b738ec7a3aa208cc449472
gem 'traject', github: 'traject/traject', require: false, branch: 'allow_nil_default'

gem 'resque-status'
gem 'resque-pool'

# for bin/ingest-etd
gem 'curb'

# When parsing the ETD metadata file from ProQuest,
# some of the dates are American-style.
gem 'american_date', '~> 1.1.0'

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec-activemodel-mocks'
  gem 'factory_girl_rails', '~> 4.4'
  gem 'jettywrapper'
  # gem 'http_logger'
  gem 'capybara'
  gem 'poltergeist'
  gem 'byebug'
  gem 'sqlite3'
  gem 'spring'
  gem 'spring-commands-rspec', group: :development
  gem 'awesome_print'
end

group :test do
  gem 'timecop', '0.7.3'
  gem 'webmock', require: false
  gem 'vcr'
  gem 'database_cleaner'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-rails', '>= 1.1.3'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
end
