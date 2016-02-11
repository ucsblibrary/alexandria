# Agent is a class in FOAF that has possible subclasses of
# Person, Group, or Organization.
# See:  http://xmlns.com/foaf/spec/#term_Agent
class Agent < ActiveFedora::Base
  include LocalAuthorityBase

  rdf_label ::RDF::Vocab::FOAF.name

  property :foaf_name, predicate: ::RDF::Vocab::FOAF.name, multiple: false do |index|
    index.as :stored_searchable, :symbol # Need :symbol for exact match for ObjectFactory find_or_create_* methods.
  end

  property :label, predicate: ::RDF::RDFS.label
  before_save :sync_label

  def sync_label
    self.label = Array(foaf_name)
  end

end
