class LocalSubjectSearchBuilder < Hydra::SearchBuilder
  # TODO: Restrict to subjects
  self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr]
end
