require 'object_factory_writer'
require 'traject/macros/marc_format_classifier'
require 'traject/macros/marc21_semantics'
require 'traject/extract_work_type'
require 'traject/extract_ark'
require 'traject/extract_fulltext_link'
require 'traject/extract_contributors'
require 'traject/extract_language'
require 'traject/extract_issue_number'
require 'traject/extract_matrix_number'
require 'traject/extract_issue_date'
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats
extend ExtractWorkType
extend ExtractArk
extend ExtractFulltextLink
extend ExtractContributors
extend ExtractLanguage
extend ExtractIssueDate
extend ExtractIssueNumber
extend ExtractMatrixNumber

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
to_field 'work_type', extract_work_type
to_field 'issued_attributes', extract_issue_date
to_field 'marc_subjects', extract_marc('650', trim_punctuation: true)
to_field 'extent', extract_marc('300a')
to_field 'issue_number', extract_issue_number
to_field 'matrix_number', extract_matrix_number
to_field 'form_of_work', extract_marc('655a', trim_punctuation: true)
to_field 'language', extract_language
to_field 'place_of_publication', extract_marc('264a', trim_punctuation: true)
to_field 'publisher', extract_marc('264b', trim_punctuation: true)
to_field 'system_number', extract_marc('001')
to_field 'title', extract_marc('245ab', trim_punctuation: true)

to_field 'contributors', extract_contributors

to_field 'description', extract_marc('520a')
to_field 'fulltext_link', extract_fulltext_link

# This is the cylinder name
to_field 'filename', extract_marc('852j')
