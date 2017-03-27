# frozen_string_literal: true

module ControlledVocabularies
  class Organization < ActiveTriples::Resource
    include LinkedVocabs::Controlled
    include ::Solrize

    configure repository: :vocabs
    configure rdf_label: RDF::SKOS.hiddenLabel
    use_vocabulary :lc_orgs, class: Vocabularies::LC_ORGS
    property :label, predicate: RDF::RDFS.label
  end
end
