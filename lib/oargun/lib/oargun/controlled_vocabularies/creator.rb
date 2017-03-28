# frozen_string_literal: true

module Oargun::ControlledVocabularies
  class Creator < ActiveTriples::Resource
    include Oargun::RDF::Controlled
  end
end
