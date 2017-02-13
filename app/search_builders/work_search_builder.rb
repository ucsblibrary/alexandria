# frozen_string_literal: true
class WorkSearchBuilder < CurationConcerns::WorkSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
