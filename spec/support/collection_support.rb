module CollectionSupport
  def create_collection_with_images(collection_attrs, attrs_for_images)
    AdminPolicy.ensure_admin_policy_exists

    coll_defaults = { admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }
    collection = Collection.create!(coll_defaults.merge(collection_attrs))

    id = Time.now.strftime('%m%d%Y%M%S') + rand(1_000_000).to_s
    defaults = { admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
                 identifier: [id] }

    attrs_for_images.each do |attrs|
      image = FactoryGirl.create(:image, defaults.merge(attrs))
      collection.ordered_members << image
    end
    collection.save!
    collection
  end
end
