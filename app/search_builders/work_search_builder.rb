# frozen_string_literal: true

class WorkSearchBuilder < Hyrax::WorkSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
