# frozen_string_literal: true

WORK_TYPE_MAP = {
  "a" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/txt"),
  "t" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/txt"),
  "e" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/car"),
  "f" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/car"),
  "c" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/not"),
  "d" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/not"),
  "i" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/aun"),
  "j" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/aum"),
  "k" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/img"),
  "g" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/mov"),
  "r" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/art"),
  "m" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/mul"),
  "p" => RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/mix"),
}.freeze

module ExtractWorkType
  # Transfer leader field 006 into a LOC Resource Type URI
  def extract_work_type
    lambda do |record, accumulator|
      # example:
      #   LEADER 01488njm a2200385 a 4500
      # we want "j" from that leader field
      accumulator << WORK_TYPE_MAP[record.leader.slice(6)]
    end
  end
end
