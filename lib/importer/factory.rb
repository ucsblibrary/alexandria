# frozen_string_literal: true

module Importer::Factory
  extend ActiveSupport::Autoload

  eager_autoload do
    autoload :AudioRecordingFactory
    autoload :CollectionFactory
    autoload :ComponentMapFactory
    autoload :ETDFactory
    autoload :ImageFactory
    autoload :IndexMapFactory
    autoload :Job
    autoload :MapSetFactory
    autoload :ObjectFactory
    autoload :ScannedMapFactory
    autoload :WithAssociatedCollection
  end

  def self.for(model_name)
    const_get "#{model_name}Factory"
  end
end
