class AudioRecording < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata
  include MarcMetadata

  property :issue_number,
           predicate: ::RDF::URI('http://id.loc.gov/vocabulary/identifiers/issue-number') do |index|
    index.as :displayable
  end

  include NestedAttributes
  validates :title, presence: { message: 'Your work must have a title.' }

  def self.indexer
    ObjectIndexer
  end
end
