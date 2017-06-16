# frozen_string_literal: true

require "rails_helper"

feature "Image show page:" do
  # TODO: Add test that ensures URIs are being dereferenced before display
  # let(:creator) { ['http://id.loc.gov/authorities/names/n81038526'] }
  let(:creator) { ["Century Company"] }
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }

  let(:title) do
    ["Region around the North Pole : giving the records of the most important explorations"]
  end

  let(:collection) do
    create(:collection,
           title: ["HECK"],
           identifier: ["ark:/99999/YES"])
  end

  let(:image) do
    create(:image,
           admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
           creator: creator,
           extent: extent,
           local_collection_id: [collection.id],
           scale: scale,
           title: title)
  end

  # See config/routes.rb: routing for images is a little weird
  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", image.id)

    expect(page).to have_content extent.first
    expect(page).to have_content creator.first
    expect(page).to have_content scale.first
    expect(page).to have_content title.first
  end
end
