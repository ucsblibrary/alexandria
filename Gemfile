source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.3'
# Use postgres in production as the database for Active Record
gem 'pg'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'hydra-head', '9.2.0'
gem 'active-fedora', '9.2.1'

gem 'active-triples', github: 'jcoyne/ActiveTriples', branch: '0.7-future'
gem 'hydra-editor', '~> 1.0.4'
gem 'hydra-role-management'
gem 'hydra-collections', '~> 5.0.1'
gem 'rdf-marmotta', '~> 0.0.8'

gem 'blacklight', '~> 5.14.0'
gem 'settingslogic'

gem 'rsolr', '~> 1.0.12'
gem 'activefedora-aggregation', '~> 0.3.0'

gem 'mods', '~> 2.0.3'
gem 'oargun', github: 'curationexperts/oargun', ref: '38f16d2'
gem 'linked_vocabs', github: 'jcoyne/linked_vocabs', branch: 'with_0.7_validation'
gem 'blacklight-gallery'
gem 'riiif', '~> 0.1.0'
gem 'ezid-client', '~> 1.0'
gem 'qa', '~> 0.5.0'

gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'

gem 'devise'
gem "devise_ldap_authenticatable"
gem 'devise-guests', github: 'cbeer/devise-guests'
gem 'traject', require: false

gem 'resque-status'
gem 'resque-pool'

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
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
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

