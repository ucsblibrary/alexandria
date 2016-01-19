class LocalNameSearchBuilder < Hydra::SearchBuilder
  # TODO: need to restrict to Names
  self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr]
end

