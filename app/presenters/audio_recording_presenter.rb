class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate(
    :alternative,
    :extent,
    :issue_number,
    :issued,
    :matrix_number,
    :notes,
    :place_of_publication,
    :restrictions,
    :table_of_contents,
    to: :solr_document
  )
end
