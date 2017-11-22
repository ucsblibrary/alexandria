# frozen_string_literal: true

require_relative "settings"
def configure_repositories
  ActiveTriples::Repositories.clear_repositories!
  vocab_repo = if Rails.env.production?
                 # rubocop:disable Metrics/LineLength
                 RDF::Marmotta.new("http://#{Rails.application.secrets.marmotta_host}:8080/marmotta")
                 # rubocop:enable Metrics/LineLength
               else
                 RDF::Repository.new
               end
  ActiveTriples::Repositories.add_repository :vocabs, vocab_repo
end

configure_repositories
Rails.application.config.to_prepare do
  configure_repositories
end
