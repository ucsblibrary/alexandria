# frozen_string_literal: true

module Oargun::RDF
  module Controlled
    extend ActiveSupport::Concern
    include Oargun::RDF::DeepIndex

    included do
      include LinkedVocabs::Controlled
      configure repository: :vocabs
    end
  end
end
