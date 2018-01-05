# frozen_string_literal: true

WORK_TYPE_MAP = {
  "a" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/txt"] },
  "t" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/txt"] },
  "e" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/car"] },
  "f" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/car"] },
  "c" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/not"] },
  "d" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/not"] },
  "i" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/aun"] },
  "j" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/aum"] },
  "k" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/img"] },
  "g" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/mov"] },
  "r" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/art"] },
  "m" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/mul"] },
  "p" => { _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/mix"] },
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
