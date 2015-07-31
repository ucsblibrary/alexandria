require 'active_fedora/aggregation'
class ETD < ActiveFedora::Base
  include Metadata
  include LocalAuthorityHashAccessor

  include Hydra::AccessControls::Embargoable
  include EmbargoBehavior

  property :system_number, predicate: ::RDF::Vocab::MODS.recordIdentifier do |index|
    index.as :symbol
  end

  property :isbn, predicate: ::RDF::Vocab::Identifiers.isbn do |index|
    index.as :symbol
  end

  property :degree_grantor, predicate: ::RDF::Vocab::MARCRelators.dgg do |index|
    index.as :symbol
  end

  property :keywords, predicate: ::RDF::DC11.subject do |index|
    index.as :stored_searchable
  end

  property :issued, predicate: ::RDF::DC.issued do |index|
    index.as :displayable
  end

  include NestedAttributes
  include Hydra::Collections::Collectible
  aggregates :generic_files, predicate: ::RDF::URI("http://pcdm.org/models#hasMember")

  contains :proquest

  def self.indexer
    ETDIndexer
  end

  def to_param
    Identifier.noidify(id)
  end

  # When a collection of these are rendered, which partial should be used
  def to_partial_path
    'catalog/document'
  end
end
