require 'traject'
require File.expand_path('../config/environment',  __FILE__)
Rails.application.eager_load!
AdminPolicy.ensure_admin_policy_exists
require 'object_factory_writer'
require 'traject/macros/marc_format_classifier'
require 'traject/macros/marc21_semantics'
require 'solrizer'
require_relative 'app/utils/identifier'
extend Traject::Macros::Marc21Semantics
extend Traject::Macros::MarcFormats

settings do
  provide "writer_class_name", "ObjectFactoryWriter"
  provide "marc_source.type", "xml"
end

ark_extractor = MarcExtractor.new("024a", :separator => nil)

to_field 'identifier', lambda { |record, accumulator, context|
  fields = ark_extractor.extract(record).map do |field|
    field
  end.compact
  if fields.empty?
    puts "No ARK, Skipping."
    context.skip!
  else
    # TODO update ARK to point at alexandria-v2?
    accumulator << fields.first
  end
}

to_field 'id', lambda { |record, accumulator, context|
  accumulator << Identifier.ark_to_id(context.output_hash['identifier'].first)
}

to_field "system_number", extract_marc("001")
to_field "language", marc_languages
to_field "created_start", marc_publication_date
to_field 'isbn', extract_marc("020a")
to_field 'title', extract_marc("245a", trim_punctuation: true)
to_field 'author', extract_marc("100a", trim_punctuation: true)
to_field 'place_of_publication', extract_marc("264a", trim_punctuation: true)
to_field 'publisher', extract_marc("264b", trim_punctuation: true)
to_field 'issued', extract_marc("264c", trim_punctuation: true)
to_field 'extent', extract_marc("300a")
to_field 'dissertation_degree', extract_marc("502b")
to_field 'dissertation_institution', extract_marc("502c")
to_field 'dissertation_year', extract_marc("502d", trim_punctuation: true)

# Names with relators, e.g. thesis advisor
to_field 'names',    extract_marc("720a")
to_field 'relators', extract_marc("720e", allow_duplicates: true)
to_field 'description', extract_marc("520a")

to_field 'degree_grantor', extract_marc("710ab", trim_punctuation: true)

extract856u = MarcExtractor.new("856u", :separator => nil)
to_field 'fulltext_link', lambda { |record, accumulator|
  accumulator << extract856u.extract(record).grep(/proquest/).first
}

to_field 'filename', extract_marc("956f")
