# frozen_string_literal: true

class EmbargoForm
  include HydraEditor::Form

  self.model_class = Hydra::AccessControls::Embargo

  self.terms = []

  delegate :admin_policy_id, to: :model

  def embargo_release_date
    model.embargo_release_date || Date.tomorrow.beginning_of_day
  end

  def visibility_options(_)
    AdminPolicy.all.invert
  end

  def embargo?
    model.embargo_release_date.present?
  end

  def visibility_after_embargo_id
    vis_after = model.embargo.try(:visibility_after_embargo)
    return unless vis_after
    ActiveFedora::Base.uri_to_id(vis_after.id)
  end
end
