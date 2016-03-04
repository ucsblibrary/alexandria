module Importer::Factory
  class ETDFactory < ObjectFactory
    include WithAssociatedCollection

    self.klass = ETD
    self.attach_files_service = AttachFilesToETD
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
  end
end
