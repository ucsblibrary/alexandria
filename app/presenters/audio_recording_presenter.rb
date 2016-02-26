class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate :restrictions, to: :solr_document
end
