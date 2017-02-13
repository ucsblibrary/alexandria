# frozen_string_literal: true
module Oargun::ControlledVocabularies
  class RightsStatement < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    configure rdf_label: RDF::Vocab::DC11.title

    use_vocabulary :eurights, class: Oargun::Vocabularies::EURIGHTS
    use_vocabulary :ccpublic, class: Oargun::Vocabularies::CCPUBLIC
    use_vocabulary :rights, class: Oargun::Vocabularies::RIGHTS
    use_vocabulary :cclicenses, class: Oargun::Vocabularies::CCLICENSES

    def rdf_label
      if rdf_subject.to_s =~ /opaquenamespace/
        term = RDF::Vocabulary.find_term(rdf_subject.to_s)
        raise TermNotFound, rdf_subject.to_s unless term
        Array(term.label)
      else
        super
      end
    end
  end
end
