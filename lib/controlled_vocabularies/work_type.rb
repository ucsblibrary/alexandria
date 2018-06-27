# frozen_string_literal: true

class ControlledVocabularies::WorkType < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  use_vocabulary :aat, class: Vocabularies::AAT
  use_vocabulary :gf, class: Vocabularies::GF
  use_vocabulary :lcsh, class: Vocabularies::LCSH
  use_vocabulary :ldp, class: ::RDF::Vocab::LDP
end
