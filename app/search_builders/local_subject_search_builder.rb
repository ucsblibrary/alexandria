# frozen_string_literal: true

class LocalSubjectSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  # TODO: Restrict to subjects
  self.default_processor_chain = [:default_solr_parameters, :add_query_to_solr]
end
