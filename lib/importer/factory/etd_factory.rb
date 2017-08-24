# frozen_string_literal: true

require "proquest"

module Importer::Factory
  class ETDFactory < ObjectFactory
    self.klass = ETD
    self.system_identifier_field = :system_number

    def attach_files(object, files)
      return unless files[:xml]
      object.proquest.mime_type = "application/xml"
      object.proquest.original_name = File.basename(files[:xml])
      object.proquest.content = File.new(files[:xml])

      object.proquest.content.rewind

      # This needs to run after object.proquest.content is set
      # (because it uses that to locate the ProQuest XML) and before
      # the FileSet itself is created (otherwise they'll be left with
      # the default restricted policy, instead of having the same
      # permissions as the ETD)
      # TODO: Adding an extra #save method to fix DIGREPO-702. In the future
      # we might want to go back and see if there is another way to fix this.
      r = Proquest::Metadata.new(object)
      r.etd.save
      r.run
      # FIXME: Currently the actual ETD has no special status among
      # the FileSets attached to the object; the catalog/_files
      # partial just assumes the first one is the ETD and the rest are
      # supplements:
      # https://github.library.ucsb.edu/ADRL/alexandria/issues/45
      ([files[:pdf]] + files[:supplements]).each do |path|
        # Skip files with the same name as an already-attached file
        next if object.file_sets.any? do |fs|
          fs.files.any? do |file|
            file.file_name.any? { |f| f == File.basename(path) }
          end
        end

        file_set = FileSet.new(admin_policy_id: object.admin_policy_id)
        logger.info "Attaching binary #{path}"
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.new(path),
                                            :original_file)
        EmbargoService.copy_embargo(object, file_set) if object.under_embargo?
        object.ordered_members << file_set
      end
    end

    def create_attributes
      # When we first create an ETD, we might not yet have the
      # metadata from ProQuest that contains the access and
      # embargo data.  Since we don't know whether or not this
      # ETD is under embargo, we'll assume the most strict
      # access level.  This policy might change later when the
      # ProQuest metadata gets imported.
      super.merge(
        admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID,
        copyright_status: [
          RDF::URI(
            "http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr"
          ),
        ],
        license: [RDF::URI("http://rightsstatements.org/vocab/InC/1.0/")]
      )
    end
  end
end
