module Oargun::ControlledVocabularies
  class Subject < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    use_vocabulary :lcsh, class: Oargun::Vocabularies::LCSH
    use_vocabulary :lcnames, class: Oargun::Vocabularies::LCNAMES
    use_vocabulary :tgm, class: Oargun::Vocabularies::TGM
    use_vocabulary :aat, class: Oargun::Vocabularies::AAT

  end
end
