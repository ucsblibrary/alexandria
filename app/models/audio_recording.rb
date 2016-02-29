class AudioRecording < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata
  include MarcMetadata

  property :issue_number,
           predicate: ::RDF::URI('http://id.loc.gov/vocabulary/identifiers/issue-number') do |index|
    index.as :displayable
  end

  property :matrix_number,
           predicate: ::RDF::URI('http://id.loc.gov/vocabulary/identifiers/matrix-number') do |index|
    index.as :displayable
  end

  property :issued, predicate: ::RDF::Vocab::DC.issued, class_name: 'TimeSpan'
  accepts_nested_attributes_for :issued, reject_if: :time_span_blank, allow_destroy: true

  include NestedAttributes
  validates :title, presence: { message: 'Your work must have a title.' }

  def self.indexer
    AudioRecordingIndexer
  end
end
