Riiif::Image.file_resolver = Riiif::HTTPFileResolver.new
Riiif::Image.info_service = lambda do |_id, _file|
  # resp = get_solr_response_for_doc_id id
  # doc = resp.first['response']['docs'].first
  { height: '', width: '' } # doc['height_isi'], width: doc['width_isi'] }
end

### ActiveSupport::Benchmarkable (used in Blacklight::SolrHelper) depends on a logger method

def logger
  Rails.logger
end

Riiif::Image.file_resolver.id_to_uri = lambda do |id|
  ActiveFedora::Base.id_to_uri(CGI.unescape(id)).tap do |url|
    logger.info "Riiif resolved #{id} to #{url}"
  end
end
Riiif::Image.file_resolver.basic_auth_credentials = [ActiveFedora.fedora.user, ActiveFedora.fedora.password]

Riiif::Engine.config.cache_duration_in_days = 365
