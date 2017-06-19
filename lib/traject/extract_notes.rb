# frozen_string_literal: true

module ExtractNotes
  def extract_notes
    lambda do |record, accumulator|
      accumulator << [
        Traject::MarcExtractor.new(
          "500a:590a", separator: '\n\n'
        ).extract(record).compact,

        Traject::MarcExtractor.new("511a").extract(record).map do |performer|
          { type: :performer, name: performer }
        end,

        Traject::MarcExtractor.new("518abop3").extract(record).map do |venue|
          { type: :venue, name: venue }
        end,

        Traject::MarcExtractor.new("561a").extract(record).map do |owner|
          { type: :ownership, name: owner }
        end,
      ]
      accumulator.flatten!
    end
  end
end
