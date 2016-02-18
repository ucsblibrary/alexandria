class AudioRecording < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include Metadata
  include MarcMetadata
  include NestedAttributes
  validates :title, presence: { message: 'Your work must have a title.' }
end
