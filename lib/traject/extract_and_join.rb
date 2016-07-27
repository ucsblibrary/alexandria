module ExtractAndJoin
  def extract_and_join(fields)
    extractor = Traject::MarcExtractor.new(fields)
    lambda do |record, accumulator|
      extents = extractor.extract(record).compact.join(' ')
      accumulator << extents
    end
  end
end
