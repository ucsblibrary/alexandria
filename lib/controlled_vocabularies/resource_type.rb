# frozen_string_literal: true

require "rdf/vocab"
module ControlledVocabularies
  class ResourceType < ActiveTriples::Resource
    include LinkedVocabs::Controlled
    include ::Solrize

    configure repository: :vocabs
    use_vocabulary :lcrt, class: Vocabularies::LCRT
  end
end
