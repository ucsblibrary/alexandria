class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate(
    :alternative,
    :extent,
    :form_of_work,
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
