require_relative 'settings'
def configure_repositories
  ActiveTriples::Repositories.clear_repositories!
  vocab_repo = if ENV['CI']
                 RDF::Repository.new
               else
                 RDF::Marmotta.new("http://#{Settings.marmotta_host}/marmotta")
               end
  ActiveTriples::Repositories.add_repository :vocabs, vocab_repo
end

configure_repositories
Rails.application.config.to_prepare do
  configure_repositories
end
