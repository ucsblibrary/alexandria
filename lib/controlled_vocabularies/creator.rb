# frozen_string_literal: true

module ControlledVocabularies
  class Creator < ActiveTriples::Resource
    include LinkedVocabs::Controlled
    include ::Solrize

    configure repository: :vocabs
  end
end
