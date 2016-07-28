module ExtractAndJoin
  def extract_and_join(fields, options = {})
    separator = options.fetch(:separator, ' ')

    extractor = Traject::MarcExtractor.new(fields, separator: separator)
    lambda do |record, accumulator|
      accumulator << extractor.extract(record).compact
      accumulator.flatten!
    end
  end
end
