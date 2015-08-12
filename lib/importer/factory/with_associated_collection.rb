module Importer
  module Factory
    module WithAssociatedCollection
      def create_attributes
        super.except(:collection).merge(collections: [find_collection])
      end

      def update_attributes
        super.except(:collection).merge(collections: [find_collection])
      end

      def find_collection
        collection_attrs = attributes.fetch(:collection).merge(admin_policy_id: attributes[:admin_policy_id])
        CollectionFactory.new(collection_attrs).run do |coll|
          coll.save!
        end
      end
    end
  end
end
