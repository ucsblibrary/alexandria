# This is a local name authority adapter for questioning authority
#

class LocalNames
  include Blacklight::SearchHelper
  include Blacklight::Configurable

  copy_blacklight_config_from CatalogController

  configure_blacklight do |conf|
    # conf.search_builder_class = LocalNameSearchBuilder
    conf.default_solr_params = {
      qf: 'foaf_name_tesim',
      fl: 'foaf_name_tesim id',
    }
  end

  def initialize(_)
  end

  def search(q)
    # TODO: need to restrict to Names
    _, list = search_results({ q: q }, [:default_solr_parameters,
                                        :add_query_to_solr])
    list.map { |d| { id: ActiveFedora::Base.id_to_uri(d.id), label: d[:foaf_name_tesim].first } }
  end

  # class LocalNameSearchBuilder < BlacklightSearchBuilder
  # end
end
