# frozen_string_literal: true

require "rdf"

module Oargun::Vocabularies
  class EURIGHTS < ::RDF::StrictVocabulary("http://www.europeana.eu/rights/")
    # Other terms
    property :"rr-f/"
    property :"rr-r/"
    property :"unknown/"
  end
end
