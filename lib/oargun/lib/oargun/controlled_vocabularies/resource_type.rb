require 'rdf/vocab'
module Oargun::ControlledVocabularies
  class ResourceType < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    use_vocabulary :lcrt, class: Oargun::Vocabularies::LCRT
  end
end
