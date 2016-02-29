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
        super
        return unless attributes.key?(:collection)
        add_to_collection(obj, collection)

        # Reindex the object with the collection label.
        obj.update_index
      end

      def add_to_collection(obj, collection)
        collection.ordered_members << obj
        collection.save!
      end

      private

        def collection
          collection_attrs = attributes.fetch(:collection).merge(admin_policy_id: attributes[:admin_policy_id])
          CollectionFactory.new(collection_attrs).find_or_create
        end
    end
  end
end
