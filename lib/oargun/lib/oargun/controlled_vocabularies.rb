module Oargun::ControlledVocabularies
  extend ActiveSupport::Autoload
  autoload :Geographic
  autoload :Subject
  autoload :WorkType
  autoload :Creator
  autoload :Language
  autoload :Organization
  autoload :RightsStatement
  autoload :CopyrightStatus
  autoload :ResourceType

  # used when unable to find a registered term for a given URI
  class TermNotFound < StandardError; end
end
