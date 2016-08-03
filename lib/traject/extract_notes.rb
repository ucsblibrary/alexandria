module ExtractNotes
  def extract_notes
    basic_ext = Traject::MarcExtractor.new('500ab3', separator: '\n\n')
    performer_ext = Traject::MarcExtractor.new('511a')
    venue_ext = Traject::MarcExtractor.new('518abop3')

    lambda do |record, accumulator|
      accumulator << basic_ext.extract(record).compact
      accumulator << performer_ext.extract(record).map { |performer| { type: :performer, name: performer } }
      accumulator << venue_ext.extract(record).map { |venue| { type: :venue, name: venue } }

      accumulator.flatten!
    end
  end
end
