class SearchBuilder < Hydra::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
  include BlacklightRangeLimit::RangeLimitBuilder
  include CurationConcerns::FilterByType
end
