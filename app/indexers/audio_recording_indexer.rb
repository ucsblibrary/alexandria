# frozen_string_literal: true

class AudioRecordingIndexer < ObjectIndexer
  def thumbnail_path
    ActionController::Base.helpers.image_path(
      "fontawesome/black/png/256/music.png"
    )
  end

  def generate_solr_document
    super do |solr_doc|
      solr_doc[ISSUED] = issued
    end
  end

  private

    def issued
      return if object.issued.blank?
      object.issued.first.display_label
    end
end
