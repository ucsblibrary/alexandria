class CollectionsSearchBuilder < Hydra::Collections::SearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
