module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = AudioRecording
    self.attach_files_service = AttachFilesToAudioRecording
    self.system_identifier_field = :system_number

    # All AudioRecordings should be public
    def create_attributes
      super.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
                  restrictions: ['MP3 files of the restored cylinders available for download are copyrighted by the Regents of the University of California. They are licensed for non-commercial use under a Creative Commons Attribution-Noncommercial License. Acknowledgments for reuse of the transfers should read "University of California, Santa Barbara Library." The original wav files (either unedited or restored) can be provided upon request for commercial or non-commercial use such as CD reissues, film/tv synchronization, use on websites or in exhibits. The University of California makes no claims or warranties as to the copyright status of the original recordings and charges a use fee for the use of the transfers. Please contact the University of California, Santa Barbara Library Department of Special Research Collections for information on licensing cylinder transfers.'])
    end
  end
end
