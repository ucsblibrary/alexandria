# frozen_string_literal: true

class ControlledVocabularies::RightsStatement < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  configure rdf_label: RDF::Vocab::DC11.title

  use_vocabulary :eurights, class: Vocabularies::EURIGHTS
  use_vocabulary :ccpublic, class: Vocabularies::CCPUBLIC
  use_vocabulary :rights, class: Vocabularies::RIGHTS
  use_vocabulary :cclicenses, class: Vocabularies::CCLICENSES

  def rdf_label
    if rdf_subject.to_s =~ /opaquenamespace/
      term = RDF::Vocabulary.find_term(rdf_subject.to_s)
      raise ::TermNotFound, rdf_subject.to_s unless term
      Array(term.label)
    else
      super
    end
  end
end
