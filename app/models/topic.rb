class Topic < ActiveFedora::Base
  include LocalAuthorityBase

  property :label, predicate: ::RDF::SKOS.prefLabel do |index|
    index.as :stored_searchable, :symbol # Need :symbol for exact match for ObjectFactory find_or_create_* methods.
  end

  def to_param
    Identifier.noidify(id)
  end
end
