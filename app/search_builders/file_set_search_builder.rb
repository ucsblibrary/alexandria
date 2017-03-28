# frozen_string_literal: true

class FileSetSearchBuilder < CurationConcerns::FileSetSearchBuilder
  include Hydra::PolicyAwareAccessControlsEnforcement
end
