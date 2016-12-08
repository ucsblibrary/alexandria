module Oargun::ControlledVocabularies
  class Language < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    use_vocabulary :iso_639_2, class: Oargun::Vocabularies::ISO_639_2
  end
end
