# frozen_string_literal: true
require "rails_helper"

feature "Accessing records:" do
  let(:restricted_image) do
    create :image, :restricted, title: ["Restricted Image"],
                                identifier: ["ark:/99999/111"], id: "111"
  end

  let(:discovery_image) do
    create :image, :discovery, title: ["Discovery Image"],
                               identifier: ["ark:/99999/222"], id: "222"
  end

  let(:public_image) do
    create :public_image, title: ["Public Image"],
                          identifier: ["ark:/99999/333"], id: "333"
  end

  let(:members) { [restricted_image, discovery_image, public_image] }

  let(:collection) do
    c = create :public_collection
    c.members += members
    c.save!
    c
  end

  before do
    %w(111 222 333).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end

    AdminPolicy.ensure_admin_policy_exists
    login_as(user) if user
  end

  context "a metadata admin" do
    let(:user) { create :metadata_admin }

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
    let(:user) { nil }

    scenario "views a collection and members" do
      visit collection_path(collection)
      expect(page).to     have_link public_image[:title].first
      expect(page).to     have_link discovery_image[:title].first
      expect(page).to_not have_link restricted_image[:title].first
    end
  end
end
