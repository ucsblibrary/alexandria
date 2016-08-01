module ExtractAndJoin
  def extract_and_join(fields, options = {})
    fieldsep = options.fetch(:field, nil)
    subfieldsep = options.fetch(:subfield, ' ')

    extractor = Traject::MarcExtractor.new(fields, separator: subfieldsep)
    lambda do |record, accumulator|
      extracted = extractor.extract(record).compact
      accumulator << (fieldsep ? extracted.join(fieldsep) : extracted)
      accumulator.flatten!
    end
  end
end
