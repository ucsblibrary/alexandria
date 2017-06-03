# frozen_string_literal: true

class ControlledVocabularies::Language < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  use_vocabulary :iso_639_2, class: Vocabularies::ISO_639_2
end
