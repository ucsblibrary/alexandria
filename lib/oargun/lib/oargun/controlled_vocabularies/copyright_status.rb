module Oargun::ControlledVocabularies
  class CopyrightStatus < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    use_vocabulary :lccs, class: Oargun::Vocabularies::LCCS

  end
end
