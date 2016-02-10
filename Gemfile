source 'https://rubygems.org'

gem 'rails', '4.2.5'
gem 'pg', '0.18.4'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

gem 'uglifier', '~> 2.7.2'
gem 'jquery-rails', '~> 4.0.5'

gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'therubyracer', platforms: :ruby

gem 'hydra-role-management'
gem 'hydra-collections', github: 'projecthydra/hydra-collections'
gem 'curation_concerns', github: 'projecthydra-labs/curation_concerns'
gem 'active-triples', '~> 0.7.5'
gem 'rdf-marmotta', '~> 0.0.8'
gem 'rdf-vocab', '~> 0.8.4'

gem 'blacklight', '~> 6.0.1'
gem 'blacklight_range_limit', '~> 6.0.0'
gem 'blacklight-gallery', '~> 0.5.0'
gem 'settingslogic'

gem 'rsolr', '~> 1.0.12'

gem 'mods', '~> 2.0.3'
gem 'oargun', github: 'curationexperts/oargun', ref: 'fbadc10181a73d6fd2cec218f6f16fe20a1f2ea2'
gem 'linked_vocabs', '~> 0.3.1'
gem 'riiif', '~> 0.2.0'
gem 'ezid-client', '~> 1.2.0'
gem 'qa', '~> 0.5.0'

gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'

gem 'devise', '~> 3.5.2'
gem 'devise_ldap_authenticatable'
gem 'devise-guests', '~> 0.5.0'

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
  gem 'rubocop', require: false
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
  gem 'capistrano', '3.4.0'
  gem 'capistrano-rails', '>= 1.1.3'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
end
