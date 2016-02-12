module CollectionSupport
  def create_collection_with_images(collection_attrs, attrs_for_images)
    coll_defaults = { admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }
    collection = Collection.create!(coll_defaults.merge(collection_attrs))

    attrs_for_images.each do |attrs|
      image = FactoryGirl.create(:public_image, attrs)
      collection.ordered_members << image
    end
    collection.save!
    collection
  end
end
