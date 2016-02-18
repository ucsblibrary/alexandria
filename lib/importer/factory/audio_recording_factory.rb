module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    include WithAssociatedCollection
    def klass
      AudioRecording
    end

    def system_identifier_field
      :system_number
    end
  end
end
