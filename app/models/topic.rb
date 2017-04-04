# frozen_string_literal: true

class Topic < ActiveFedora::Base
  include LocalAuthorityBase

  property :label, predicate: ::RDF::RDFS.label do |index|
    # Need :symbol for exact match for ObjectFactory find_or_create_*
    # methods.
    index.as :stored_searchable, :symbol
  end
end
