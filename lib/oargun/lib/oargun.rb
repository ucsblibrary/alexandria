require 'oargun/version'
require 'active_support'
require 'active_triples'
require 'linked_vocabs'

module Oargun
  extend ActiveSupport::Autoload
  autoload :ControlledVocabularies
  autoload :RDF
  autoload :Vocabularies
end
