# frozen_string_literal: true
class ScannedMapPresenter < CurationConcerns::WorkShowPresenter
  delegate(
    :accession_number,
    :alternative,
    :ark,
    :citation,
    :collection,
    :copyright_status,
    :creator,
    :extent,
    :form_of_work,
    :fulltext_link,
    :issue_number,
    :issued,
    :license,
    :location,
    :matrix_number,
    :notes,
    :place_of_publication,
    :restrictions,
    :rights_holder,
    :scale,
    :sub_location,
    :table_of_contents,
    :work_type,
    to: :solr_document
  )
end
