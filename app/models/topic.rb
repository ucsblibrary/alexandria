class Topic < ActiveFedora::Base
  include LocalAuthorityBase

  property :label, predicate: ::RDF::RDFS.label do |index|
    index.as :stored_searchable, :symbol # Need :symbol for exact match for ObjectFactory find_or_create_* methods.
  end
end
