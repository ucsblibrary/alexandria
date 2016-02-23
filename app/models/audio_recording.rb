class AudioRecording < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata
  include MarcMetadata
  include NestedAttributes
  validates :title, presence: { message: 'Your work must have a title.' }

  def self.indexer
    ObjectIndexer
  end
end
