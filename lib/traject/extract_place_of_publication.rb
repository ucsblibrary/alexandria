# frozen_string_literal: true

module ExtractPlaceOfPublication
  # As of
  # https://github.com/traject/traject/commit/0a0dfe308f1a90398eaf4ebede7b8d74f747742e,
  # Traject trims periods more rigorously, so this is to ensure the
  # trailing dot isn't removed from "Orange, N.J."
  def extract_place_of_publication
    places = Traject::MarcExtractor.new("260a:264a", separator: nil)
    lambda do |record, accumulator|
      places.extract(record).compact.each do |r|
        accumulator << r.sub(/\ :$/, "")
      end
    end
  end
end
