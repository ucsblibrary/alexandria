class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate :restrictions, :alternative, to: :solr_document
end
