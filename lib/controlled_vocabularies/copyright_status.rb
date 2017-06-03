# frozen_string_literal: true

class ControlledVocabularies::CopyrightStatus < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
  use_vocabulary :lccs, class: Vocabularies::LCCS
end
