class AudioRecordingPresenter < CurationConcerns::WorkShowPresenter
  delegate(
    :accession_number,
    :alternative,
    :copyright_status,
    :extent,
    :form_of_work,
    :issue_number,
    :issued,
    :location,
    :matrix_number,
    :notes,
    :place_of_publication,
    :restrictions,
    :rights_holder,
    :sub_location,
    :table_of_contents,
    to: :solr_document
  )
end
