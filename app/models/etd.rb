# frozen_string_literal: true

class ETD < ActiveFedora::Base
  include CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata
  include MarcMetadata
  include LocalAuthorityHashAccessor
  include HumanReadableType
  include EmbargoBehavior

  self.human_readable_type = "Thesis or dissertation"

  validates :title, presence: { message: "Your work must have a title." }

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

  property :issued, predicate: ::RDF::Vocab::DC.issued do |index|
    index.as :displayable
  end

  include NestedAttributes

  has_subresource :proquest

  def self.indexer
    ETDIndexer
  end

  def embargo_indexer_class
    EmbargoIndexer
  end

  # Override CC
  # https://github.com/projecthydra/curation_concerns/blob/5680a3317c14cca1928476c74a91a5dc6703feda/app/models/concerns/curation_concerns/work_behavior.rb#L33-L42
  def self._to_partial_path
    "catalog/document"
  end
end
