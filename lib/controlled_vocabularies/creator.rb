# frozen_string_literal: true

class ControlledVocabularies::Creator < ActiveTriples::Resource
  include LinkedVocabs::Controlled
  include ::Solrize

  configure repository: :vocabs
end
