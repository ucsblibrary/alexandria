class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate :restrictions, :alternative, :issue_number, :matrix_number,
           :issued, to: :solr_document
end
