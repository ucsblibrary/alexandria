class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate :restrictions, :alternative, :issue_number,
    to: :solr_document
end
