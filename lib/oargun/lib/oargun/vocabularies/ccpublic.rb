require 'rdf'

module Oargun::Vocabularies
  class CCPUBLIC < ::RDF::StrictVocabulary("http://creativecommons.org/publicdomain/")

    # Other terms
    property :"mark/1.0/"
    property :"zero/1.0/"
  end
end
