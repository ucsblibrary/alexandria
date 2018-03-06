# frozen_string_literal: true

require "rails_helper"

describe "Collection search page", js: true do
  before do
    # Since we're testing the search results, we need to ensure the
    # images we're interested in don't spill over to the second page
    # of results
    Collection.destroy_all
    Image.destroy_all
  end

  context "with collections" do
    let!(:collection1) { create(:public_collection, title: ["Red"]) }
    let!(:collection2) do
      create(:public_collection, title: ["Pink"],
                                 id: "fk4v989d9j",
                                 identifier: ["ark:/99999/fk4v989d9j"],
                                 extent: ["7 photos"])
    end

    it "Search for a collection" do
      visit collections_path

      fill_in "q", with: "Pink"
      click_button "Search"
      expect(page).not_to have_content "Red"
      click_link "Pink"

      # View collection metadata
      expect(page).to have_content "Pink"
      expect(page).to have_content "7 photos"
    end
  end

  context "collections with images" do
    let(:pink) do
      {
        title: ["Pink"],
        identifier: ["pink"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      }
    end

    let(:orange) do
      {
        title: ["Orange"],
        identifier: ["orange"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      }
    end

    let(:banana) do
      {
        title: ["Banana"],
        identifier: ["banana"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      }
    end

    let(:colors_attrs) { { title: ["Colors"] } }
    let(:fruits_attrs) { { title: ["Fruits"] } }

    let!(:colors) do
      create_collection_with_images(colors_attrs, [pink, orange])
    end

    let!(:fruits) do
      create_collection_with_images(fruits_attrs, [orange, banana])
    end

    it "Search within a collection" do
      visit collection_path(colors)

      expect(page).to have_link("Pink", href: "/lib/pink")
      expect(page).to have_link("Orange", href: "/lib/orange")
      expect(page).not_to have_link("Banana", href: "/lib/banana")

      # Search for something that's not in this collection
      fill_in "collection_search", with: banana[:title].first
      click_button "collection_submit"

      expect(page).to have_content "No entries found"

      # Search for something within the collection:
      fill_in "collection_search", with: orange[:title].first
      click_button "collection_submit"

      expect(page).not_to have_link("Pink", href: "/lib/pink")
      expect(page).to have_link("Orange", href: "/lib/orange")
      expect(page).not_to have_link("Banana", href: "/lib/banana")
    end

    it "Search with main search bar instead of within the collection" do
      visit collection_path(colors)

      expect(page).to have_link("Pink", href: "/lib/pink")
      expect(page).to have_link("Orange", href: "/lib/orange")
      expect(page).not_to have_link("Banana", href: "/lib/banana")

      # Search for something that's not in this collection
      fill_in "q", with: banana[:title].first
      click_button "Search"

      expect(page).not_to have_link("Pink", href: "/lib/pink")
      expect(page).not_to have_link("Orange", href: "/lib/orange")
      expect(page).to have_link("Banana", href: "/lib/banana")
    end
  end
end
