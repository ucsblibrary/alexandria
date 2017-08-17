# frozen_string_literal: true

require "identifier"
require "object_factory_writer"
require "traject/macros/marc_format_classifier"
require "traject/macros/marc21_semantics"
require "traject/extract_and_join"
require "traject/extract_ark"
require "traject/extract_complex_subject"
require "traject/extract_contributors"
require "traject/extract_fulltext_link"
require "traject/extract_issue_date"
require "traject/extract_issue_number"
require "traject/extract_language"
require "traject/extract_lc_subject"
require "traject/extract_matrix_number"
require "traject/extract_notes"
require "traject/extract_place_of_publication"
require "traject/extract_work_type"
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats
extend ExtractAndJoin
extend ExtractArk
extend ExtractComplexSubject
extend ExtractContributors
extend ExtractFulltextLink
extend ExtractIssueDate
extend ExtractIssueNumber
extend ExtractLCSubject
extend ExtractLanguage
extend ExtractMatrixNumber
extend ExtractNotes
extend ExtractPlaceOfPublication
extend ExtractWorkType

settings do
  provide "allow_empty_fields", true
  provide "marc_source.type", "xml"
  provide "writer_class_name", "ObjectFactoryWriter"

  # Don't use threads. Workaround for
  # https://jira.duraspace.org/browse/FCREPO-2086
  #
  # TODO: remove when we upgrade to 4.7
  provide "processing_thread_pool", 0
end

to_field "identifier", extract_ark
to_field(
  "id",
  lambda do |_record, accumulator, context|
    accumulator << Identifier.ark_to_id(
      context.output_hash["identifier"].first
    )
  end
)

to_field "accession_number", extract_marc("852j")
to_field "alternative", extract_marc("130:240:246:740a", trim_punctuation: true)
to_field "contributors", extract_contributors
to_field "description", extract_and_join("520a", field: '\n')
to_field "edition", extract_marc("250a")
to_field "extent", extract_marc("300abce", trim_punctuation: true)
to_field "form_of_work", extract_marc("600v:610v:650v:651v:655a",
                                      trim_punctuation: true)
to_field "fulltext_link", extract_fulltext_link
to_field "issue_number", extract_issue_number
to_field "issued_attributes", extract_issue_date
to_field "language", extract_language
to_field "lc_subject", extract_lc_subject
to_field "location", extract_marc("650z:651az", trim_punctuation: true)
to_field "marc_subjects", extract_complex_subject
to_field "matrix_number", extract_matrix_number
to_field "note", extract_notes
to_field "place_of_publication", extract_place_of_publication
to_field "publisher", extract_marc("260b:264b", trim_punctuation: true)
to_field "system_number", extract_marc("001")
to_field "table_of_contents", extract_marc("505agrtu68")
to_field "title", extract_marc("245abnp", trim_punctuation: true)
to_field "work_type", extract_work_type
