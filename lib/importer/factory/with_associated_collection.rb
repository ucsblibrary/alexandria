module Importer
  module Factory
    module WithAssociatedCollection
      def create_attributes
        super.except(:collection)
      end

      def update_attributes
        super.except(:collection)
      end

      def after_save(obj)
        add_object_to_collection(obj, attributes)
      end

      def add_object_to_collection(obj, attrs)
        collection_attrs = attrs.fetch(:collection).merge(admin_policy_id: attributes[:admin_policy_id])
        CollectionFactory.new(collection_attrs).run do |coll|
          coll.members << obj
          coll.save!
        end
        # reload the collectoin association so we can reindex with the collection
        obj.association(:collections).reload
        obj.update_index
      end
    end
  end
end
