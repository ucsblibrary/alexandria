# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include CurationConcerns::SearchFilters
  include BlacklightRangeLimit::RangeLimitBuilder
  include CurationConcerns::FilterByType
  include Hydra::PolicyAwareAccessControlsEnforcement
end
