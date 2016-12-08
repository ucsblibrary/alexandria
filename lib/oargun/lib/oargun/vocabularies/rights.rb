require 'rdf'
module Oargun::Vocabularies
  class RIGHTS < ::RDF::StrictVocabulary("http://opaquenamespace.org/ns/rights/")

    property :"educational/", label: "Educational Use Permitted"
    property :"orphan-work-us/", label: "Orphan Work"

  end
end
