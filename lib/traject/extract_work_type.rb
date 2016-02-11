module ExtractWorkType
  def extract_work_type
    work_type = {
      'a' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt'),
      't' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt'),
      'e' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/car'),
      'f' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/car'),
      'c' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/not'),
      'd' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/not'),
      'i' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aun'),
      'j' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/aum'),
      'k' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/img'),
      'g' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/mov'),
      'r' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/art'),
      'm' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/mul'),
      'p' => RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/mix')
    }
    lambda { |record, accumulator|
      accumulator << work_type[record.leader.slice(6)]
    }
  end
end
