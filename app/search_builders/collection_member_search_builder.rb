# frozen_string_literal: true

class CollectionMemberSearchBuilder < Hyrax::CollectionMemberSearchBuilder
  # https://github.com/projecthydra/curation_concerns/wiki/Solr-Search-Builders
  def filter_models(solr_parameters)
    solr_parameters[:fq] << "-{!terms f=has_model_ssim}" +
                            ComponentMap.to_rdf_representation
  end
end
