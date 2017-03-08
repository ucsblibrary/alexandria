# frozen_string_literal: true
require "rails_helper"

feature "IndexMap show page:" do
  let(:creator) { "http://id.loc.gov/authorities/names/n81038526" }
  let(:creator_uri) { RDF::URI.new(creator) }
  let(:title) { ["Region around the North Pole : giving the records of the most important explorations"] }
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }
  let(:map) do
    VCR.use_cassette("show_index_map_feature_spec") do
      FactoryGirl.create(:public_index_map, title: title, creator: [creator_uri], extent: extent, scale: scale)
    end
  end

  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "Century Company"
    expect(page).to have_content scale.first
  end
end
