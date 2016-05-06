module Importer::Factory
  class ETDFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = ETD
    self.system_identifier_field = :system_number

    def create_attributes
      # When we first create an ETD, we might not yet have the
      # metadata from ProQuest that contains the access and
      # embargo data.  Since we don't know whether or not this
      # ETD is under embargo, we'll assume the most strict
      # access level.  This policy might change later when the
      # ProQuest metadata gets imported.
      super.merge(admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID)
    end

    def attach_files(object, files)
      return unless files[:xml]
      object.proquest.mime_type = 'application/xml'
      object.proquest.original_name = File.basename(files[:xml])
      object.proquest.content = File.new(files[:xml])

      Proquest::Metadata.new(object).run

      object.proquest.content.rewind

      # FIXME: Currently the actual ETD has no special status among
      # the FileSets attached to the object; the catalog/_files
      # partial just assumes the first one is the ETD and the rest are
      # supplements:
      # https://github.library.ucsb.edu/ADRL/alexandria/issues/45
      ([files[:pdf]] + files[:supplements]).each do |path|
        file_set = FileSet.new(admin_policy_id: object.admin_policy_id)
        Rails.logger.debug "Attaching binary #{path}"
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.new(path),
                                            :original_file)
        EmbargoService.copy_embargo(object, file_set) if object.under_embargo?
        object.ordered_members << file_set
      end
    end
  end
end
