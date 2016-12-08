module Oargun::ControlledVocabularies
  class Organization < ActiveTriples::Resource
    include Oargun::RDF::Controlled

    use_vocabulary :lc_orgs, class: Oargun::Vocabularies::LC_ORGS
    configure :rdf_label => RDF::SKOS.hiddenLabel

    property :label, :predicate => RDF::RDFS.label
  end
end
