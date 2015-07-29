module EmbargoHelper

  # Because we're storing admin policies in the embargos, we need to lookup the object.
  def after_visibility(curation_concern)
    Hydra::AdminPolicy.find(curation_concern.visibility_after_embargo).try(:title)
  end
end
