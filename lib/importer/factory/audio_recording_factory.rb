module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    include WithAssociatedCollection
    def klass
      AudioRecording
    end

    def system_identifier_field
      :system_number
    end

    def after_save(audio)
      super # Calls after_save in WithAssociatedCollection
      return unless files_directory && attributes[:files]

      Rails.logger.warn "Files for AudioRecording #{audio.id} were: #{attributes[:files]}, expected only 1" unless attributes[:files].size == 1

      AttachFilesToAudioRecording.run(audio, files_directory, attributes[:files])
      audio.save # force a reindex after the files are created
    end
  end
end
