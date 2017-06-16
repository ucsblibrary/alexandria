# frozen_string_literal: true

class Collection < ActiveFedora::Base
  include CurationConcerns::CollectionBehavior
  include Metadata
  include WithAdminPolicy

  property :issued, predicate: ::RDF::Vocab::DC.issued, class_name: TimeSpan

  property :date_copyrighted,
           predicate: ::RDF::Vocab::DC.dateCopyrighted,
           class_name: TimeSpan

  accepts_nested_attributes_for(
    :creator,
    reject_if: lambda { |attributes| attributes[:id].blank? }
  )

  accepts_nested_attributes_for(
    :collector,
    reject_if: lambda { |attributes| attributes[:id].blank? }
  )

  accepts_nested_attributes_for :issued,
                                reject_if: :time_span_blank,
                                allow_destroy: true

  accepts_nested_attributes_for :date_copyrighted,
                                reject_if: :time_span_blank,
                                allow_destroy: true

  # must be included after all properties are declared
  include NestedAttributes

  def self.indexer
    CollectionIndexer
  end
end
