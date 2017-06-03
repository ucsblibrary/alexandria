# frozen_string_literal: true

class ControlledVocabularies::ResourceType < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  use_vocabulary :lcrt, class: Vocabularies::LCRT
end
