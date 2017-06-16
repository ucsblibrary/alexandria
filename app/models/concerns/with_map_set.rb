# frozen_string_literal: true

module WithMapSet
  # When this object is created or updated, its parent MapSet
  # needs to update its solr index
  def map_set_update_index
    MapSet.find(parent_id).update_index if parent_id
  rescue ActiveFedora::ObjectNotFoundError
    Rails.logger.error(
      "Could not find expected parent_id #{parent_id} for object #{id}"
    )
  end
end
