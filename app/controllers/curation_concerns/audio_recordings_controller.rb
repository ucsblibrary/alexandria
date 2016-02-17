# Generated via
#  `rails generate curation_concerns:work AudioRecording`

class CurationConcerns::AudioRecordingsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type AudioRecording
end
