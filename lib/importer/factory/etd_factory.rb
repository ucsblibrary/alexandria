module Importer::Factory
  class ETDFactory < ObjectFactory
    include WithAssociatedCollection

    def klass
      ETD
    end

    def update(obj)
      update_created_date(obj)
      super
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

    def log_created(obj)
      puts "  Created #{klass.to_s.downcase} #{obj.id} (#{attributes[:system_number].first})"
    end

    def log_updated(obj)
      puts "  Updated #{klass.to_s.downcase} #{obj.id} (#{attributes[:system_number].first})"
    end

    private

      def update_created_date(obj)
        created_attributes = attributes.delete(:created_attributes)
        return if created_attributes.blank?

        new_date = created_attributes.first.fetch(:start, nil)
        return unless new_date

        existing_date = obj.created.flat_map(&:start)

        if existing_date != new_date
          # Create or update the existing date.
          if time_span = obj.created.to_a.first
            time_span.update(created_attributes.first)
          else
            obj.created.build(created_attributes.first)
          end
        end
      end
  end
end
