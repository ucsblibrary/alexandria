# frozen_string_literal: true

module Importer::Factory
  class AudioRecordingFactory < ObjectFactory
    self.klass = AudioRecording
    self.system_identifier_field = :system_number

    # @param [AudioRecording] object
    # @param [Array<Array>] cylinders
    #
    # Each AudioRecording may have several cylinders attached.
    # Each cylinder will have an original and restored copy.
    # So `cylinders' is an array of arrays:
    #  [
    #    ['/opt/ingest/special/cusb-cyl2118a.wav',
    #     '/opt/ingest/special/cusb-cyl2118b.wav'],

    #    ['/opt/ingest/special/cusb-cyl2119a.wav',
    #     '/opt/ingest/special/cusb-cyl2119b.wav'],
    # ]
    def attach_files(object, cylinders)
      return if object.file_sets.count.positive?
      cylinders.each do |filegroup|
        next if filegroup.empty?
        number = cylinder_number(filegroup)
        next unless number

        now = CurationConcerns::TimeService.time_in_utc

        file_set = FileSet.create!(
          label: "Cylinder#{number}",
          admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
          date_uploaded: now,
          date_modified: now
        )

        actor = CurationConcerns::Actors::FileSetActor.new(
          file_set, User.batchuser
        )

        # Set the representative if it doesn't already exist and a
        # file was attached.
        object.representative ||= file_set if attach_original(actor,
                                                              number,
                                                              filegroup)
        attach_restored(actor, number, filegroup)
        object.ordered_members << file_set
      end
    end

    def cylinder_number(filegroup)
      original = filegroup.map do |f|
        f.match(/.*cusb-cyl(\d+)a.wav$/)
      end.compact.first

      if original.nil?
        logger.warn "Could not extract cylinder number "\
                       "from: #{filegroup.join(", ")}"
        return nil
      end

      restored = filegroup.detect do |f|
        f.match(/.*cusb-cyl#{original[1]}b.wav$/)
      end

      if restored.nil?
        logger.warn "Missing restored WAV in #{filegroup.join(", ")}"
        return nil
      end

      original[1]
    end

    # @param [CurationConcerns::FileSetActor] actor
    # @param [String] number
    # @param [Array] cylinders
    def attach_original(actor, number, cylinders)
      orig_path = cylinders.select do |c|
        c.include? "cusb-cyl#{number}a.wav"
      end.first

      if orig_path
        logger.info "Attaching original #{orig_path}"
        actor.create_content(File.new(orig_path))
      else
        logger.warn "No original file provided for Cylinder #{number}"
      end
    end

    # @param [CurationConcerns::FileSetActor] actor
    # @param [String] number
    # @param [Array] cylinders
    def attach_restored(actor, number, cylinders)
      rest_path = cylinders.select do |c|
        c.include? "cusb-cyl#{number}b.wav"
      end.first

      if rest_path
        logger.info "Attaching restored #{rest_path}"
        actor.create_content(File.new(rest_path), "restored")
      else
        logger.warn "No restored file provided for Cylinder #{number}"
      end
    end

    RESTRICTIONS = [
      "MP3 files of the restored cylinders available for download "\
      "are copyrighted by the Regents of the University of California. "\
      "They are licensed for non-commercial use under a Creative Commons "\
      "Attribution-Noncommercial License. Acknowledgments for reuse "\
      "of the transfers should read \"University of California, "\
      "Santa Barbara Library.\" The original wav files "\
      "(either unedited or restored) can be provided upon request "\
      "for commercial or non-commercial use such as CD reissues, "\
      "film/tv synchronization, use on websites or in exhibits. "\
      "The University of California makes no claims or warranties "\
      "as to the copyright status of the original recordings "\
      "and charges a use fee for the use of the transfers. "\
      "Please contact the University of California, Santa Barbara "\
      "Library Department of Special Research Collections "\
      "for information on licensing cylinder transfers.",
    ].freeze

    # All AudioRecordings should be public
    def create_attributes
      super.merge(
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        copyright_status: [
          RDF::URI(
            "http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr"
          ),
        ],
        digital_origin: ["reformatted digital"],
        institution: [
          RDF::URI("http://id.loc.gov/vocabulary/organizations/cusb"),
        ],
        license: [RDF::URI("http://creativecommons.org/licenses/by-nc/2.5/")],
        restrictions: RESTRICTIONS,
        rights_holder: [
          RDF::URI("http://id.loc.gov/authorities/names/n85088322"),
        ],
        sub_location: ["Department of Special Research Collections"]
      )
    end
  end
end
