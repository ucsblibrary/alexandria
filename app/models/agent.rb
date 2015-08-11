# Agent is a class in FOAF that has possible subclasses of
# Person, Group, or Organization.
# See:  http://xmlns.com/foaf/spec/#term_Agent

class Agent < ActiveFedora::Base
  include LocalAuthorityBase

  rdf_label ::RDF::FOAF.name
  property :foaf_name, predicate: ::RDF::FOAF.name, multiple: false do |index|
    index.as :stored_searchable, :symbol  # Need :symbol for exact match for ObjectFactory find_or_create_* methods.
  end

  # This asserts that this record is valid for a vocab. This works around
  # the LinkedVocabs::Validators::PropertyValidator
  def in_vocab?
    true
  end

  def to_param
    Identifier.noidify(id)
  end

  # When a collection of these are rendered, which partial should be used
  def to_partial_path
    'catalog/document'
  end

  # This allows us to scope queries directly against a specific subclass,
  # Otherwise, "Agent.all" would return instances of any subclass of Agent
  # (e.g. Person)
  def self.exact_model
    where(has_model_ssim: self.to_s)
  end

end
