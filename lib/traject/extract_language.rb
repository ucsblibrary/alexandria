# frozen_string_literal: true

module ExtractLanguage
  # Transform field 008 into an iso639-2 URI
  def extract_language
    lang_extractor = Traject::MarcExtractor.new("008[35-37]")
    lambda do |record, accumulator|
      abbrev = lang_extractor.extract(record).compact.first
      # Check for empty strings
      return if /\s/ =~ abbrev

      accumulator << { _rdf: ["http://id.loc.gov/vocabulary/iso639-2/#{abbrev}"] }
    end
  end
end
