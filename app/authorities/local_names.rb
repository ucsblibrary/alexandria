# This is a local name authority adapter for questioning authority
class LocalNames
  include Blacklight::SearchHelper
  include Blacklight::Configurable

  copy_blacklight_config_from CatalogController

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: 'foaf_name_tesim',
      fl: 'foaf_name_tesim id',
    }
    config.search_builder_class = LocalNameSearchBuilder
  end

  def initialize(_)
  end

  def search(q)
    _, list = search_results(q: q)
    list.map { |d| { id: ActiveFedora::Base.id_to_uri(d.id), label: d[:foaf_name_tesim].first } }
  end
end
