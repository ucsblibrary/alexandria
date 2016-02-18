class WorkSearchBuilder < CurationConcerns::WorkSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
