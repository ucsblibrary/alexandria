class Image < ActiveFedora::Base
  include CurationConcerns::WorkBehavior
  include Metadata
  include WithAdminPolicy
  include EmbargoBehavior
  include LocalAuthorityHashAccessor

  self.human_readable_type = 'Image'

  validates :title, presence: { message: 'Your work must have a title.' }

  property :issued, predicate: ::RDF::Vocab::DC.issued, class_name: 'TimeSpan'
  property :date_copyrighted, predicate: ::RDF::Vocab::DC.dateCopyrighted, class_name: 'TimeSpan'

  accepts_nested_attributes_for :issued, reject_if: :time_span_blank, allow_destroy: true
  accepts_nested_attributes_for :date_copyrighted, reject_if: :time_span_blank, allow_destroy: true

  validates_vocabulary_of :rights_holder
  validates_vocabulary_of :form_of_work

  # must be included after all properties are declared
  include NestedAttributes

  def self.indexer
    ImageIndexer
  end

  # When a collection of these are rendered, which partial should be used
  def to_partial_path
    'catalog/document'
  end
end
