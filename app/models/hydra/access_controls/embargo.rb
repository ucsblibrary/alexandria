# frozen_string_literal: true

# Override from hydra-access-controls gem so the title of
# the visibility will be captured in the history message.
require Hydra::Engine.root.to_s + "/app/models/hydra/access_controls/embargo"

module Hydra::AccessControls
  class Embargo < ActiveFedora::Base
    # The log message used when deactivating an embargo
    def embargo_history_message(state, deactivate_date, release_date, visibility_during, visibility_after)
      vis_during_label = ::EmbargoService.title_for(visibility_during.id)
      vis_after_label  = ::EmbargoService.title_for(visibility_after.id)

      I18n.t "hydra.embargo.history_message",
             state: state,
             deactivate_date: deactivate_date,
             release_date: release_date,
             visibility_during: vis_during_label,
             visibility_after: vis_after_label
    end
  end
end
