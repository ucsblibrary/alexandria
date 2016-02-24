module EmbargoService
  def self.create_or_update_embargo(work, params)
    if new_admin_policy_id = params[:admin_policy_id]
      # This path is for new embargos
      during = resource_for(new_admin_policy_id)
      work.visibility_during_embargo = during
      work.admin_policy_id = new_admin_policy_id
    end
    work.visibility_after_embargo = resource_for(params[:visibility_after_embargo_id])
    work.embargo_release_date = params[:embargo_release_date]
    work.embargo.save!
  end

  def self.copy_embargo(src, dest)
    dest.visibility_during_embargo = RDF::URI(src.visibility_during_embargo.id)
    dest.visibility_after_embargo = RDF::URI(src.visibility_after_embargo.id)
    dest.embargo_release_date = src.embargo_release_date
    dest.embargo.save!
  end

  def self.remove_embargo(work)
    work.embargo.destroy if work.embargo
    # TODO: this shouldn't be necessary, but if omitted raises a stack trace:
    work.embargo = nil
  end

  private

    def self.resource_for(id)
      RDF::URI(ActiveFedora::Base.id_to_uri(id))
    end
end
