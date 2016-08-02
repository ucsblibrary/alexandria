require 'object_factory_writer'
require 'traject/macros/marc_format_classifier'
require 'traject/macros/marc21_semantics'
require 'traject/extract_and_join'
require 'traject/extract_ark'
require 'traject/extract_contributors'
require 'traject/extract_fulltext_link'
require 'traject/extract_issue_date'
require 'traject/extract_issue_number'
require 'traject/extract_language'
require 'traject/extract_matrix_number'
require 'traject/extract_work_type'
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats
extend ExtractAndJoin
extend ExtractArk
extend ExtractContributors
extend ExtractFulltextLink
extend ExtractIssueDate
extend ExtractIssueNumber
extend ExtractLanguage
extend ExtractMatrixNumber
extend ExtractWorkType

settings do
  provide 'writer_class_name', 'ObjectFactoryWriter'
  provide 'marc_source.type', 'xml'
  # Don't use threads. Workaround for https://github.com/fcrepo4/fcrepo4/issues/880
  provide 'processing_thread_pool', 0
  provide 'allow_empty_fields', true
end

to_field 'identifier', extract_ark
to_field 'id', lambda { |_record, accumulator, context|
  accumulator << Identifier.ark_to_id(context.output_hash['identifier'].first)
}

to_field 'alternative', extract_marc('130:240:246:740')
to_field 'contributors', extract_contributors
to_field 'description', extract_and_join('520a', field: '\n\n')
to_field 'extent', extract_marc('300abce')
to_field 'form_of_work', extract_marc('600v:655a', trim_punctuation: true)
to_field 'fulltext_link', extract_fulltext_link
to_field 'issue_number', extract_issue_number
to_field 'issued_attributes', extract_issue_date
to_field 'language', extract_language
to_field 'marc_subjects', extract_marc('650', trim_punctuation: true)
to_field 'matrix_number', extract_matrix_number
to_field 'note', extract_and_join('500ab3', subfield: '\n\n')
to_field 'place_of_publication', extract_marc('260a:264a', trim_punctuation: true)
to_field 'publisher', extract_marc('260b:264b', trim_punctuation: true)
to_field 'system_number', extract_marc('001')
to_field 'table_of_contents', extract_marc('505agrtu68')
to_field 'title', extract_marc('245ab', trim_punctuation: true)
to_field 'work_type', extract_work_type

# This is the cylinder name
to_field 'filename', extract_marc('852j')
