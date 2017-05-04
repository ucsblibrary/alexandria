# frozen_string_literal: true

require "rails_helper"

feature "Accessing records:" do
  let(:collection) do
    create(:collection,
           admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
           title: ["HECK"],
           identifier: ["ark:/99999/YES"])
  end

  let!(:restricted_image) do
    create(:image,
           admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID,
           id: "111",
           identifier: ["ark:/99999/111"],
           local_collection_id: [collection.id],
           title: ["Restricted Image"])
  end

  let!(:discovery_image) do
    create(:image,
           admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID,
           id: "222",
           identifier: ["ark:/99999/222"],
           local_collection_id: [collection.id],
           title: ["Discovery Image"])
  end

  let!(:public_image) do
    create(:public_image,
           id: "333",
           identifier: ["ark:/99999/333"],
           local_collection_id: [collection.id],
           title: ["Public Image"])
  end

  before do
    allow_any_instance_of(CollectionsController).to receive(:current_user).and_return(user)
    allow_any_instance_of(CatalogController).to receive(:current_user).and_return(user)
    allow_any_instance_of(RecordsController).to receive(:current_user).and_return(user)

    collection.update_index
  end

  context "a metadata admin" do
    let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

    scenario "views a collection and members" do
      visit collection_path(collection)

      expect(page).to have_link public_image[:title].first
      expect(page).to have_link discovery_image[:title].first
      expect(page).to have_link restricted_image[:title].first

      click_link restricted_image[:title].first
      expect(page).to have_current_path(catalog_ark_path("ark:", "99999", restricted_image.id))
      expect(page).to have_content(restricted_image.title.first)

      expect(page).to have_link("Edit Metadata")
      click_link "Edit Metadata"

      fill_in "Title", with: "A special new title"
      click_button "Save"
      expect(page).to have_content("A special new title")
      expect(page).to have_link("Edit Metadata")
    end
  end

  context "a not logged in user" do
    let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }

    scenario "views a collection and members" do
      visit collection_path(collection)
      expect(page).to     have_link public_image[:title].first
      expect(page).to     have_link discovery_image[:title].first
      expect(page).to_not have_link restricted_image[:title].first
    end
  end
end
