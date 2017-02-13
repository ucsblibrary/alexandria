# frozen_string_literal: true
require "rails_helper"

feature "Collection show page:" do
  let(:red_attrs) do
    { title: ["Red"],
      contributor: ["Coloring book"],
      identifier: ["ark:/99999/fk4zp46p1g"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID, }
  end
  let(:pink_attrs) do
    { title: ["Pink"],
      contributor: ["Coloring book", "Pinko"],
      identifier: ["ark:/99999/fk4v989d9j"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID, }
  end

  let(:colors_attrs) do
    { title: ["Colors"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID, }
  end

  before do
    AdminPolicy.ensure_admin_policy_exists
    login_as user
  end

  let!(:colors) { create_collection_with_images(colors_attrs, [red_attrs, pink_attrs]) }

  let(:user) { create :user }

  scenario "Use facets to browse collection members" do
    visit collection_path(colors)
    expect(page).to have_content red_attrs[:title].first
    expect(page).to have_content pink_attrs[:title].first

    within("#facets #facet-all_contributors_label_sim") do
      click_link "Coloring book"
    end
    expect(page).to have_content red_attrs[:title].first
    expect(page).to have_content pink_attrs[:title].first

    within("#facets #facet-all_contributors_label_sim") do
      click_link "Pinko"
    end
    expect(page).to_not have_content red_attrs[:title].first
    expect(page).to have_content pink_attrs[:title].first
  end
end
