require 'active_fedora/aggregation'
class Image < ActiveFedora::Base
  include Metadata
  include NestedAttributes
  include Hydra::Collections::Collectible
  include LocalAuthorityHashAccessor

  include Hydra::AccessControls::Embargoable
  include EmbargoBehavior

  aggregates :generic_files, predicate: ::RDF::URI("http://pcdm.org/models#hasMember")

  has_and_belongs_to_many :issued, predicate: ::RDF::DC.issued, class_name: 'TimeSpan', inverse_of: :issued_images
  accepts_nested_attributes_for :issued, reject_if: :time_span_blank, allow_destroy: true

  def self.indexer
    ImageIndexer
  end

  def to_param
    Identifier.noidify(id)
  end

end
