module ExtractAndJoin
  def extract_and_join(options = {})
    fields = options.fetch(:field)
    separator = options.fetch(:separator, ' ')

    extractor = Traject::MarcExtractor.new(fields, separator: separator)
    lambda do |record, accumulator|
      accumulator << extractor.extract(record).compact
      accumulator.flatten!
    end
  end
end
