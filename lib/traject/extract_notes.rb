module ExtractNotes
  def extract_notes
    basic_ext = Traject::MarcExtractor.new('500ab3', separator: '\n\n')
    performer_ext = Traject::MarcExtractor.new('511a')

    lambda do |record, accumulator|
      accumulator << basic_ext.extract(record).compact
      accumulator << performer_ext.extract(record).map { |performer| { type: :performer, name: performer } }
      accumulator.flatten!
    end
  end
end
