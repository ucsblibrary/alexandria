module ExtractLanguage
  # Transform field 008 into an iso639-2 URI
  def extract_language
    lang_extractor = Traject::MarcExtractor.new('008[35-37]')
    lambda do |record, accumulator|
      abbrev = lang_extractor.extract(record).compact.first
      accumulator << RDF::URI("http://id.loc.gov/vocabulary/iso639-2/#{abbrev}")
    end
  end
end

