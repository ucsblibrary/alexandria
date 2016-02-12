module ExtractArk
  def extract_ark
    ark_extractor = Traject::MarcExtractor.new('024a', separator: nil)

    lambda do |record, accumulator, context|
      fields = ark_extractor.extract(record).compact
      if fields.empty?
        puts 'No ARK, Skipping.'
        context.skip!
      else
        # TODO: update ARK to point at alexandria-v2?
        accumulator << fields.first
      end
    end
  end
end
