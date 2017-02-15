# frozen_string_literal: true
require "rails_helper"

feature "ScannedMap show page:" do
  let(:creator) { ["Century Company"] }
  let(:title) { ["Region around the North Pole : giving the records of the most important explorations"] }
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }
  let(:map) do
    FactoryGirl.create(:public_scanned_map, title: title, creator: creator, extent: extent, scale: scale)
  end

  # See config/routes.rb: routing for images is a little weird
  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content creator.first
    expect(page).to have_content scale.first
  end
end
