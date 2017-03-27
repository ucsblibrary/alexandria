# frozen_string_literal: true

require "rdf/vocab"
module ControlledVocabularies
  class WorkType < ActiveTriples::Resource
    include LinkedVocabs::Controlled
    include ::Solrize

    configure repository: :vocabs
    use_vocabulary :aat, class: Vocabularies::AAT
    use_vocabulary :ldp, class: ::RDF::Vocab::LDP
    # use_vocabulary :worktype
    use_vocabulary :lcsh, class: Vocabularies::LCSH
  end
end
