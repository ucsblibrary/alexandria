# frozen_string_literal: true

module EmbargoHelper
  # Because we're storing admin policies in the embargos, we need to
  # look up the object.
  def after_visibility(curation_concern)
    uri = curation_concern.visibility_after_embargo.id
    ::EmbargoService.title_for(uri)
  end

  def works_with_expired_embargoes
    @works_with_expired_embargoes ||=
      EmbargoQueryService.works_with_expired_embargoes
  end

  def works_under_embargo
    @works_under_embargo ||= EmbargoQueryService.works_under_embargo
  end

  def assets_with_deactivated_embargoes
    @assets_with_deactivated_embargoes ||=
      EmbargoQueryService.assets_with_deactivated_embargoes
  end
end
