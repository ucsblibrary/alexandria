class Collection < ActiveFedora::Base
  include ::CurationConcerns::CollectionBehavior
  # include Hydra::AccessControls::Permissions
  include Metadata
  include LocalAuthorityHashAccessor

  accepts_nested_attributes_for :creator, reject_if: proc { |attributes| attributes[:id].blank? }
  accepts_nested_attributes_for :collector, reject_if: proc { |attributes| attributes[:id].blank? }

  has_and_belongs_to_many :issued, predicate: ::RDF::DC.issued, class_name: 'TimeSpan', inverse_of: :issued_images
  has_and_belongs_to_many :date_copyrighted, predicate: ::RDF::DC.dateCopyrighted, class_name: 'TimeSpan', inverse_of: :date_copyrighted_images

  accepts_nested_attributes_for :issued, reject_if: :time_span_blank, allow_destroy: true
  accepts_nested_attributes_for :date_copyrighted, reject_if: :time_span_blank, allow_destroy: true

  include NestedAttributes

  def self.indexer
    CollectionIndexer
  end
end
