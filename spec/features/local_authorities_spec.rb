# frozen_string_literal: true

require "rails_helper"

describe "Local Authorities", js: true do
  before do
    # Delete existing records to make sure that search and facet
    # results will contain the results the spec is looking for
    # on the first page of results.
    [Agent, Person, Group, Organization, Topic].each do |model|
      model.all.each do |record|
        record.destroy(eradicate: true)
      end
    end

    AdminPolicy.ensure_admin_policy_exists
    allow_any_instance_of(User).to(
      receive(:groups).and_return([AdminPolicy::META_ADMIN])
    )
  end

  context "with some records" do
    let!(:frodo) { create :person, foaf_name: "Frodo Baggins" }
    let!(:fellows) { create :group, foaf_name: "The Fellowship" }
    let!(:uruk) { create :organization, foaf_name: "uruk" }
    let!(:ring) { create :topic, label: ["the ring"] }

    it "browse using facets" do
      visit local_authorities_path
      click_button "Search"

      expect(page).to have_link(frodo.foaf_name)
      expect(page).to have_link(fellows.foaf_name)
      expect(page).to have_link(uruk.foaf_name)
      expect(page).to have_link(ring.label.first)

      within "#facets" do
        click_link "Person"
      end

      expect(page).to have_link(frodo.foaf_name)
      expect(page).not_to have_link(fellows.foaf_name)

      # Remove the previous facet selection
      within "#facets" do
        find("a.remove").click
      end

      expect(page).to have_link(frodo.foaf_name)
      expect(page).to have_link(fellows.foaf_name)

      within "#facets" do
        click_link "Group"
      end

      expect(page).not_to have_link(frodo.foaf_name)
      expect(page).to have_link(fellows.foaf_name)
    end

    it "Click show link from index page" do
      visit local_authorities_path
      click_button "Search"
      expect(page).to have_link(frodo.foaf_name)
      click_link frodo.foaf_name
      expect(page).to have_content("Name:\n#{frodo.foaf_name}")
    end
  end
end
