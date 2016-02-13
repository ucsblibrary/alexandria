class CollectionSearchBuilder < Hydra::Collections::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
  include CurationConcerns::SingleResult
end
