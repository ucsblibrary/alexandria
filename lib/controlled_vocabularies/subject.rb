# frozen_string_literal: true

class ControlledVocabularies::Subject < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  use_vocabulary :lcsh, class: Vocabularies::LCSH
  use_vocabulary :lcnames, class: Vocabularies::LCNAMES
  use_vocabulary :tgm, class: Vocabularies::TGM
  use_vocabulary :aat, class: Vocabularies::AAT
end
