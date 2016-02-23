class ETD < ActiveFedora::Base
  include CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata
  include MarcMetadata
  include LocalAuthorityHashAccessor
  include HumanReadableType
  include EmbargoBehavior

  self.human_readable_type = 'Thesis or dissertation'

  validates :title, presence: { message: 'Your work must have a title.' }

  property :isbn, predicate: ::RDF::Vocab::Identifiers.isbn do |index|
    index.as :symbol
  end

  property :degree_grantor, predicate: ::RDF::Vocab::MARCRelators.dgg do |index|
    index.as :symbol
  end

  property :keywords, predicate: ::RDF::Vocab::SCHEMA.keywords do |index|
    index.as :stored_searchable
  end
  property :dissertation_degree, predicate: ::RDF::Vocab::Bibframe.dissertationDegree
  property :dissertation_institution, predicate: ::RDF::Vocab::Bibframe.dissertationInstitution
  property :dissertation_year, predicate: ::RDF::Vocab::Bibframe.dissertationYear

  include NestedAttributes

  contains :proquest

  def self.indexer
    ETDIndexer
  end

  def embargo_indexer_class
    EmbargoIndexer
  end

  # When a collection of these are rendered, which partial should be used
  def to_partial_path
    'catalog/document'
  end
end
