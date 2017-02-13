# frozen_string_literal: true
require "rails_helper"

feature "Navigation menu:" do
  context "a metadata-admin user" do
    let(:meta_admin) { create(:metadata_admin) }
    before { login_as(meta_admin) }

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
    let(:rights_admin) { create(:rights_admin) }
    before { login_as(rights_admin) }

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
    let(:user) { create(:ucsb_user) }
    before { login_as(user) }

    scenario "using the navigation" do
      visit search_catalog_path

      # Shouldn't see admin links
      expect(page).to_not have_link("Local Authorities")
      expect(page).to_not have_link("Add Record")
      expect(page).to_not have_link("Embargos")
    end
  end

  context "user is not logged in" do
    scenario "using the navigation" do
      visit search_catalog_path

      # Shouldn't be able to see the admin menu items
      expect(page).to_not have_link("Local Authorities")
      expect(page).to_not have_link("Add Record")
      expect(page).to_not have_link("Embargos")
    end
  end
end
