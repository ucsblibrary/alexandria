# frozen_string_literal: true

WORK_TYPE_MAP = {
  "a" => "http://id.loc.gov/vocabulary/resourceTypes/txt",
  "t" => "http://id.loc.gov/vocabulary/resourceTypes/txt",
  "e" => "http://id.loc.gov/vocabulary/resourceTypes/car",
  "f" => "http://id.loc.gov/vocabulary/resourceTypes/car",
  "c" => "http://id.loc.gov/vocabulary/resourceTypes/not",
  "d" => "http://id.loc.gov/vocabulary/resourceTypes/not",
  "i" => "http://id.loc.gov/vocabulary/resourceTypes/aun",
  "j" => "http://id.loc.gov/vocabulary/resourceTypes/aum",
  "k" => "http://id.loc.gov/vocabulary/resourceTypes/img",
  "g" => "http://id.loc.gov/vocabulary/resourceTypes/mov",
  "r" => "http://id.loc.gov/vocabulary/resourceTypes/art",
  "m" => "http://id.loc.gov/vocabulary/resourceTypes/mul",
  "p" => "http://id.loc.gov/vocabulary/resourceTypes/mix",
}.freeze

module ExtractWorkType
  # Transfer leader field 006 into a LOC Resource Type URI
  def extract_work_type
    lambda do |record, accumulator|
      # example: njm a2200385 a 4500
      # we want "j" from that leader field
      accumulator << WORK_TYPE_MAP[record.leader.sub(/^[0-9]*/, "").slice(1)]
    end
  end
end
