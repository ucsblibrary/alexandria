# frozen_string_literal: true

class AudioRecording < ActiveFedora::Base
  include Hyrax::WorkBehavior
  include Metadata
  include MarcMetadata
  include WithAdminPolicy

  validates :title, presence: { message: "Your work must have a title." }

  property :issued, predicate: ::RDF::Vocab::DC.issued, class_name: TimeSpan

  accepts_nested_attributes_for :issued,
                                reject_if: :time_span_blank,
                                allow_destroy: true

  include NestedAttributes

  def self.indexer
    AudioRecordingIndexer
  end

  # Override CC
  # https://github.com/projecthydra/curation_concerns/blob/5680a3317c14cca1928476c74a91a5dc6703feda/app/models/concerns/curation_concerns/work_behavior.rb#L33-L42
  def self._to_partial_path
    "catalog/document"
  end
end
