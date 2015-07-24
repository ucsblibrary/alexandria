require 'rails_helper'

feature 'Collection show page:' do

  let(:red_attrs)  {{ title: 'Red',
                      publisher: ['Colors Pub', 'Red Pub'],
                      identifier: ['ark:/99999/fk4zp46p1g'],
                      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }}
  let(:pink_attrs) {{ title: 'Pink',
                      publisher: ['Colors Pub', 'Pink Pub'],
                      identifier: ['ark:/99999/fk4v989d9j'],
                      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }}

  let(:colors_attrs) {{ title: 'Colors',
                        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID }}

  let(:colors) { create_collection_with_images(colors_attrs, [red_attrs, pink_attrs]) }

  let(:user) { create :user }

  before {
    AdminPolicy.ensure_admin_policy_exists
    colors
    login_as user
  }

  scenario 'Use facets to browse collection members' do
    visit collections.collection_path(colors)
    expect(page).to have_content red_attrs[:title]
    expect(page).to have_content pink_attrs[:title]

    within('#facets #facet-publisher_sim') do
      click_link 'Colors Pub'
    end
    expect(page).to have_content red_attrs[:title]
    expect(page).to have_content pink_attrs[:title]

    within('#facets #facet-publisher_sim') do
      click_link 'Pink Pub'
    end
    expect(page).to_not have_content red_attrs[:title]
    expect(page).to     have_content pink_attrs[:title]
  end
end
