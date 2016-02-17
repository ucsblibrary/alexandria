class CurationConcerns::AudioRecordingsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type AudioRecording

  self.theme = 'alexandria'

  def search_builder_class
    ::WorkSearchBuilder
  end

  # Overrides the Blacklight::Catalog to point at main_app
  def search_action_url options = {}
    main_app.search_catalog_path(options)
  end
end
