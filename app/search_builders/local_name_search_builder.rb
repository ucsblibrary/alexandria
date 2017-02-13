# frozen_string_literal: true
class LocalNameSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  # TODO: need to restrict to Names
  self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr]
end
