module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = AudioRecording
    self.system_identifier_field = :system_number

    # @param [AudioRecording] object
    # @param [Array<Array>] cylinders
    def attach_files(object, cylinders)
      return if object.file_sets.count > 0

      # `cylinders' is an array of arrays:
      #  [
      #    ['/opt/ingest/special/cusb-cyl2118a.wav', '/opt/ingest/special/cusb-cyl2118b.wav'],
      #    ['/opt/ingest/special/cusb-cyl2119a.wav', '/opt/ingest/special/cusb-cyl2119b.wav'],
      # ]
      cylinders.each do |filegroup|
        next if filegroup.empty?
        number = filegroup.first.match(/.*cusb-cyl(\d+).\.wav/)[1]

        now = CurationConcerns::TimeService.time_in_utc
        file_set = FileSet.create!(label: "Cylinder#{number}",
                                   admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
                                   date_uploaded: now,
                                   date_modified: now)
        actor = CurationConcerns::FileSetActor.new(file_set, User.batchuser)
        # Set the representative if it doesn't already exist and a file was attached.
        object.representative ||= file_set if attach_original(actor, number, filegroup)
        attach_restored(actor, number, filegroup)
        object.ordered_members << file_set
      end
    end

    def attach_original(actor, number, cylinders)
      if orig_path = cylinders.select { |c| c.include? "cusb-cyl#{number}a.wav" }.first
        Rails.logger.debug "Attaching original #{orig_path}"
        actor.create_content(File.new(orig_path))
      else
        $stderr.puts "No original file provided for Cylinder #{number}"
      end
    end

    def attach_restored(actor, number, cylinders)
      if rest_path = cylinders.select { |c| c.include? "cusb-cyl#{number}b.wav" }.first
        Rails.logger.debug "Attaching restored #{rest_path}"
        actor.create_content(File.new(rest_path), 'restored')
      else
        $stderr.puts "No restored file provided for Cylinder #{number}"
      end
    end

    # All AudioRecordings should be public
    def create_attributes
      super.merge(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
                  restrictions: ['MP3 files of the restored cylinders available for download are copyrighted by the Regents of the University of California. They are licensed for non-commercial use under a Creative Commons Attribution-Noncommercial License. Acknowledgments for reuse of the transfers should read "University of California, Santa Barbara Library." The original wav files (either unedited or restored) can be provided upon request for commercial or non-commercial use such as CD reissues, film/tv synchronization, use on websites or in exhibits. The University of California makes no claims or warranties as to the copyright status of the original recordings and charges a use fee for the use of the transfers. Please contact the University of California, Santa Barbara Library Department of Special Research Collections for information on licensing cylinder transfers.'])
    end
  end
end
