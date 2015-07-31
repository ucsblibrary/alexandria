# This file contains some overrides to embargo behavior from
# the hydra-access-controls gem, so when you include it in a
# model, it must be included *after* you include
# Hydra::AccessControls::Embargoable.

module EmbargoBehavior
  extend ActiveSupport::Concern

  # Set the current visibility to match what is described in the embargo.
  def embargo_visibility!
    return unless embargo_release_date
    uri = under_embargo? ? embargo.visibility_during_embargo : embargo.visibility_after_embargo
    self.admin_policy_id = ActiveFedora::Base.uri_to_id(uri.id)
  end

  # Allow expired embargoes to be created
  def enforce_future_date_for_embargo?
    false
  end

end
