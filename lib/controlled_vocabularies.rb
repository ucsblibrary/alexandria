# frozen_string_literal: true

require "solrize"

module ControlledVocabularies
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
end
