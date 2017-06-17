# frozen_string_literal: true

module ExtractNotes
  def extract_notes
    basic_ext = Traject::MarcExtractor.new("500a:590a", separator: '\n\n')
    performer_ext = Traject::MarcExtractor.new("511a")
    venue_ext = Traject::MarcExtractor.new("518abop3")
    owner_ext = Traject::MarcExtractor.new("561a")

    lambda do |record, accumulator|
      accumulator << basic_ext.extract(record).compact

      accumulator << (performer_ext.extract(record).map do |performer|
                        { type: :performer, name: performer }
                      end)

      accumulator << (venue_ext.extract(record).map do |venue|
                        { type: :venue, name: venue }
                      end)

      accumulator << (owner_ext.extract(record).map do |owner|
                        { type: :ownership, name: owner }
                      end)

      accumulator.flatten!
    end
  end
end
