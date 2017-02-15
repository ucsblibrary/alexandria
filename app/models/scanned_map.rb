# Generated via
#  `rails generate curation_concerns:work ScannedMap`
class ScannedMap < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include WithAdminPolicy
  include Metadata

  validates :title, presence: { message: "Your work must have a title." }
end
