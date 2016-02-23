module Importer::Factory
  class ETDFactory < ObjectFactory
    include WithAssociatedCollection

    def klass
      ETD
    end

    def create_attributes
      # When we first create an ETD, we might not yet have the
      # metadata from ProQuest that contains the access and
      # embargo data.  Since we don't know whether or not this
      # ETD is under embargo, we'll assume the most strict
      # access level.  This policy might change later when the
      # ProQuest metadata gets imported.
      super.merge(admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID)
    end

    def after_save(etd)
      super # Calls after_save in WithAssociatedCollection
      return unless files_directory && attributes[:files]

      Rails.logger.warn "Files for etd #{etd.id} were: #{attributes[:files]}, expected only 1" unless attributes[:files].size == 1

      # Only import proquest files once
      if etd.proquest.new_record?
        # TODO: move to background job
        AttachFilesToETD.run(etd, attributes[:files].first)
      end
      etd.save # force a reindex after the files are created
    end

    def system_identifier_field
      :system_number
    end
  end
end
