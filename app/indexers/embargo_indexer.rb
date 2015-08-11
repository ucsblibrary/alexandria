class EmbargoIndexer
    def initialize(object)
      @object = object
    end

    def generate_solr_document
      {}.tap do |doc|
        date_field_name = Hydra.config.permissions.embargo.release_date.sub(/_dtsi/, '')
        Solrizer.insert_field(doc, date_field_name, @object.embargo_release_date, :stored_sortable)
        doc[visibility_during_key] = visibility_during_embargo_id
        doc[visibility_after_key] = visibility_after_embargo_id
      end
    end

    private

      def visibility_during_key
        ::Solrizer.solr_name("visibility_during_embargo", :symbol)
      end

      def visibility_after_key
        ::Solrizer.solr_name("visibility_after_embargo", :symbol)
      end

      def visibility_during_embargo_id
        return unless @object.visibility_during_embargo
        ActiveFedora::Base.uri_to_id(@object.visibility_during_embargo.id)
      end

      def visibility_after_embargo_id
        return unless @object.visibility_after_embargo
        ActiveFedora::Base.uri_to_id(@object.visibility_after_embargo.id)
      end
end
