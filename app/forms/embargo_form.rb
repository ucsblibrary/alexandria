class EmbargoForm
  include HydraEditor::Form

  self.model_class = Hydra::AccessControls::Embargo

  self.terms = []

  def admin_policy_id
    model.admin_policy_id
  end

  def embargo_release_date
    model.embargo_release_date || Date.tomorrow.beginning_of_day
  end

  def visibility_options(_)
    AdminPolicy.all
  end

  def embargo?
    !!model.embargo
  end

  def visibility_after_embargo_id
    vis_after = model.embargo.try(:visibility_after_embargo)
    return unless vis_after
    ActiveFedora::Base.uri_to_id(vis_after.id)
  end

end
