# frozen_string_literal: true

module ExtractNotes
  def extract_notes
    basic_ext = Traject::MarcExtractor.new("500a:590a", separator: '\n\n')
    performer_ext = Traject::MarcExtractor.new("511a")
    venue_ext = Traject::MarcExtractor.new("518abop3")
    owner_ext = Traject::MarcExtractor.new("561a")

    lambda do |record, accumulator|
      accumulator << basic_ext.extract(record).compact
      accumulator << (performer_ext.extract(record).map { |performer| { type: :performer, name: performer } })
      accumulator << (venue_ext.extract(record).map { |venue| { type: :venue, name: venue } })
      accumulator << (owner_ext.extract(record).map { |owner| { type: :ownership, name: owner } })

      accumulator.flatten!
    end
  end
end
