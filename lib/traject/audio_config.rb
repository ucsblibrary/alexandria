require 'traject'
require File.expand_path('../../../config/environment', __FILE__)
Rails.application.eager_load!
AdminPolicy.ensure_admin_policy_exists
require 'object_factory_writer'
require 'traject/macros/marc_format_classifier'
require 'traject/macros/marc21_semantics'
require 'traject/extract_work_type'
require 'traject/extract_ark'
require 'traject/extract_fulltext_link'
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats
extend ExtractWorkType
extend ExtractArk
extend ExtractFulltextLink

settings do
  provide 'writer_class_name', 'ObjectFactoryWriter'
  provide 'marc_source.type', 'xml'
  # Don't use threads. Workaround for https://github.com/fcrepo4/fcrepo4/issues/880
  provide 'processing_thread_pool', 0
end

to_field 'identifier', extract_ark
to_field 'id', lambda { |_record, accumulator, context|
  accumulator << Identifier.ark_to_id(context.output_hash['identifier'].first)
}

to_field 'author', extract_marc('100a', trim_punctuation: true, default: nil)
to_field 'work_type', extract_work_type
to_field 'created_start', marc_publication_date
to_field 'marc_subjects', extract_marc('650', trim_punctuation: true, default: nil)
to_field 'extent', extract_marc('300a', default: nil)
to_field 'form_of_work', extract_marc('655a', trim_punctuation: true, default: nil)
to_field 'language', marc_languages
to_field 'place_of_publication', extract_marc('264a', trim_punctuation: true, default: nil)
to_field 'publisher', extract_marc('264b', trim_punctuation: true, default: nil)
to_field 'system_number', extract_marc('001', default: nil)
to_field 'title', extract_marc('245ab', trim_punctuation: true, default: nil)

# Names with relators, e.g. thesis advisor
to_field 'names',    extract_marc('720a')
to_field 'relators', extract_marc('720e', allow_duplicates: true)
to_field 'description', extract_marc('520a', default: nil)
to_field 'fulltext_link', extract_fulltext_link

# This is the cylinder name
to_field 'filename', extract_marc('852j', default: nil)
