# frozen_string_literal: true

require "uri"

Riiif::Image.authorization_service = AuthService
Riiif::Engine.config.cache_duration_in_days = 365
Riiif::Image.file_resolver =
  Riiif::HTTPFileResolver.new(cache_path: Settings.riiif_fedora_cache)

Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ActiveFedora::Base.id_to_uri(CGI.unescape(id)).tap do |url|
    logger.info "Riiif resolved #{id} to #{url}"
  end
end

Riiif::Image.file_resolver.basic_auth_credentials = [
  ActiveFedora.fedora.user,
  ActiveFedora.fedora.password,
]

Riiif::Image.info_service = lambda do |id, _file|
  # id will look like a path to a pcdm:file
  # (e.g. rv042t299%2Ffiles%2F6d71677a-4f80-42f1-ae58-ed1063fd79c7)
  # but we just want the id for the FileSet it's attached to.
  # Capture everything before the first slash
  fs_id = URI.decode(id).sub(%r{\A([^\/]*)\/.*}, '\1')
  resp = ActiveFedora::SolrService.get("id:#{fs_id}")
  doc = resp["response"]["docs"].first
  raise "Unable to find solr document with id:#{fs_id}" unless doc
  { height: doc["height_is"], width: doc["width_is"] }
end

# ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper)
# depends on a logger method
def logger
  Rails.logger
end
