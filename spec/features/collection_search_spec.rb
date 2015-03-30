require 'rails_helper'

feature 'Collection search page' do

  let(:pink)   {{ title: 'Pink',   identifier: ['pink']   }}
  let(:orange) {{ title: 'Orange', identifier: ['orange'] }}
  let(:banana) {{ title: 'Banana', identifier: ['banana'] }}

  let(:colors_attrs) {{ title: 'Colors' }}
  let(:fruits_attrs) {{ title: 'Fruits' }}

  let(:colors) { create_collection_with_images(colors_attrs, [pink, orange]) }
  let(:fruits) { create_collection_with_images(fruits_attrs, [orange, banana]) }

  let(:user) { create :user }

  before do
    AdminPolicy.ensure_admin_policy_exists
    colors
    fruits
    sign_in user
  end

  scenario 'Search within a collection' do
    visit collections.collection_path(colors)

    expect(page).to have_selector('#documents .document', count: 2)
    expect(page).to     have_link('Pink', href: '/lib/pink')
    expect(page).to     have_link('Orange', href: '/lib/orange')
    expect(page).to_not have_link('Banana', href: '/lib/banana')

    # Search for something that's not in this collection
    fill_in 'collection_search', with: banana[:title]
    click_button 'collection_submit'

    expect(page).to have_selector('#documents .document', count: 0)
    expect(page).to have_content 'No entries found'

    # Search for something within the collection:
    fill_in 'collection_search', with: orange[:title]
    click_button 'collection_submit'

    expect(page).to have_selector('#documents .document', count: 1)
    expect(page).to_not have_link('Pink', href: '/lib/pink')
    expect(page).to     have_link('Orange', href: '/lib/orange')
    expect(page).to_not have_link('Banana', href: '/lib/banana')
  end

  scenario 'Search with the main search bar instead of within the collection' do
    visit collections.collection_path(colors)

    expect(page).to have_selector('#documents .document', count: 2)
    expect(page).to     have_link('Pink', href: '/lib/pink')
    expect(page).to     have_link('Orange', href: '/lib/orange')
    expect(page).to_not have_link('Banana', href: '/lib/banana')

    # Search for something that's not in this collection
    fill_in 'q', with: banana[:title]
    click_button 'search'

    expect(page).to have_selector('#documents .document', count: 1)
    expect(page).to_not have_link('Pink', href: '/lib/pink')
    expect(page).to_not have_link('Orange', href: '/lib/orange')
    expect(page).to     have_link('Banana', href: '/lib/banana')
  end
end
