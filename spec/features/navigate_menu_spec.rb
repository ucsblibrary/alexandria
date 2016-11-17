# frozen_string_literal: true

require "rails_helper"

feature "Navigation menu:" do
  before do
    allow_any_instance_of(User).to receive(:groups).and_return(groups)
  end

  context "a metadata-admin user" do
    let(:groups) { [AdminPolicy::META_ADMIN] }

    scenario "using the navigation" do
      visit search_catalog_path

      # The nav menu
      expect(page).to     have_link("Local Authorities")
      expect(page).to     have_link("Add Record")
      expect(page).to_not have_link("Embargos")

      # Make sure the links works
      click_link "Local Authorities"
      expect(page).to have_current_path(local_authorities_path)

      click_link "Add Record"
      expect(page).to have_content("Select an object type")
    end
  end

  context "a rights-admin user" do
    let(:groups) { [AdminPolicy::RIGHTS_ADMIN] }

    scenario "using the navigation" do
      visit search_catalog_path

      # The nav menu
      expect(page).to_not have_link("Local Authorities")
      expect(page).to_not have_link("Add Record")
      expect(page).to     have_link("Embargoes")

      # Make sure the link works
      click_link "Embargoes"
      expect(page).to have_content("All Active Embargoes")
    end
  end

  context "a UCSB student (non-privileged user, logged in)" do
    let(:groups) { [AdminPolicy::UCSB_GROUP] }

    scenario "using the navigation" do
      visit search_catalog_path

      # Shouldn't see admin links
      expect(page).to_not have_link("Local Authorities")
      expect(page).to_not have_link("Add Record")
      expect(page).to_not have_link("Embargos")
    end
  end

  context "user is not logged in" do
    let(:groups) { [AdminPolicy::PUBLIC_GROUP] }

    scenario "using the navigation" do
      visit search_catalog_path

      # Shouldn't be able to see the admin menu items
      expect(page).to_not have_link("Local Authorities")
      expect(page).to_not have_link("Add Record")
      expect(page).to_not have_link("Embargos")
    end
  end
end
