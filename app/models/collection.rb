class Collection < ActiveFedora::Base
  #include Hydra::AccessControls::Permissions
  include Hydra::Collections::Relations
  include Metadata
  include LocalAuthorityHashAccessor

  accepts_nested_attributes_for :creator, reject_if: proc { |attributes| attributes[:id].blank? }
  accepts_nested_attributes_for :collector, reject_if: proc { |attributes| attributes[:id].blank? }

  has_and_belongs_to_many :issued, predicate: ::RDF::DC.issued, class_name: 'TimeSpan', inverse_of: :issued_images
  accepts_nested_attributes_for :issued, reject_if: :time_span_blank, allow_destroy: true

  include NestedAttributes

  def self.indexer
    CollectionIndexer
  end

  def to_param
    Identifier.noidify(id)
  end

end
