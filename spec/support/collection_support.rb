# frozen_string_literal: true

module CollectionSupport
  def create_collection_with_images(collection_attrs, attrs_for_images)
    coll_defaults = { admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }
    collection = Collection.create!(coll_defaults.merge(collection_attrs))

    attrs_for_images.each do |attrs|
      FactoryBot.create(
        :image,
        attrs.merge(local_collection_id: [collection.id])
      )
    end

    collection.update_index
    collection
  end
end
