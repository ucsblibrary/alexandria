# frozen_string_literal: true

class FileSetSearchBuilder < Hyrax::FileSetSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
