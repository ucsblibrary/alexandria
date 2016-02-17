# Generated via
#  `rails generate curation_concerns:work AudioRecording`
class AudioRecording < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  validates :title, presence: { message: 'Your work must have a title.' }
end
