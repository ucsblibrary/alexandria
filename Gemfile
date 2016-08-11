source 'https://rubygems.org'
ruby '2.3.0'

group :production, :development do
  gem 'pg', '~> 0.18.4'
end

gem 'rails', '4.2.7.1'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

gem 'uglifier', '~> 2.7.2'
gem 'jquery-rails', '~> 4.0.5'

gem 'turbolinks'
gem 'jbuilder', '~> 2.0'
gem 'therubyracer', platforms: :ruby

gem 'active-triples', '~> 0.7.5'
gem 'blacklight', '~> 6.2.0'
gem 'blacklight-gallery', '~> 0.5.0'
gem 'blacklight_range_limit', '~> 6.0.0'
gem 'curation_concerns', git: 'https://github.com/dunn/curation_concerns', branch: 'bytes_lts'
gem 'ezid-client', '~> 1.2'
gem 'hydra-collections', '>= 8.1.1'
gem 'hydra-head', '~> 9.8.1'
gem 'hydra-role-management'
gem 'linked_vocabs', '~> 0.3.1'
gem 'marc'
gem 'mods', '~> 2.0.3'
gem 'oargun', git: 'https://github.com/curationexperts/oargun.git', ref: '8d4b556'
gem 'qa', '~> 0.5.0'
gem 'rdf-marmotta', '~> 0.0.8'
gem 'rdf-vocab', '~> 0.8.4'
gem 'riiif', '~> 0.2.0'
gem 'rsolr', '~> 1.0.12'
gem 'traject', '~> 2.3.0'

gem 'kaminari', '~> 0.16.3'
# https://github.com/amatsuda/kaminari/pull/636
gem 'kaminari_route_prefix'

gem 'devise', '~> 3.5.2'
gem 'devise_ldap_authenticatable'
gem 'devise-guests', '~> 0.5.0'
gem 'settingslogic'

gem 'resque-status'
gem 'resque-pool'

# for bin/ingest
gem 'curb'
gem 'trollop'

# When parsing the ETD metadata file from ProQuest,
# some of the dates are American-style.
gem 'american_date', '~> 1.1.0'

group :development, :test do
  gem 'awesome_print'
  gem 'byebug'
  gem 'factory_girl_rails', '~> 4.4'
  gem 'jettywrapper'
  gem 'poltergeist'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'spring'
  gem 'spring-commands-rspec', group: :development
end

group :test do
  gem 'capybara', '2.6.2'
  gem 'ci_reporter'
  gem 'database_cleaner'
  gem 'sqlite3'
  gem 'timecop', '0.7.3'
  gem 'vcr'
  gem 'webmock', require: false
end

group :development do
  gem 'capistrano', '3.4.0'
  gem 'capistrano-rails', '>= 1.1.3'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'

  gem 'method_source'
  gem 'pry'
  gem 'pry-doc'
end
