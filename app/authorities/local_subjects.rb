# This is a local subjects authority adapter for questioning authority
class LocalSubjects
  include Blacklight::SearchHelper
  include Blacklight::Configurable

  copy_blacklight_config_from LocalAuthoritiesController

  configure_blacklight do |config|
    config.default_solr_params = {
      qf: 'label_tesim',
      fl: 'label_tesim id',
    }
    config.search_builder_class = LocalSubjectSearchBuilder
  end

  def initialize(_)
  end

  def search(q)
    _, list = search_results(q: q)
    list.map { |d| { id: ActiveFedora::Base.id_to_uri(d.id), label: d[:label_tesim].first } }
  end
end
