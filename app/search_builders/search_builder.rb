# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Hyrax::FilterByType
  include Hydra::PolicyAwareAccessControlsEnforcement
  include BlacklightRangeLimit::RangeLimitBuilder
end
