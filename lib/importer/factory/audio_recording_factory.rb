module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    include WithAssociatedCollection
    def klass
      AudioRecording
    end

    def system_identifier_field
      :system_number
    end

    # All AudioRecordings should be public
    def create_attributes
      super.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end


    def after_save(audio)
      super # Calls after_save in WithAssociatedCollection
      return unless files_directory && attributes[:files]

      AttachFilesToAudioRecording.run(audio, files_directory, attributes[:files])
      audio.save # force a reindex after the files are created
    end
  end
end
