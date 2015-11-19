require 'rails_helper'

feature 'Collection search page' do
  let(:user) { create :user }

  before do
    AdminPolicy.ensure_admin_policy_exists
    login_as user
  end

  context 'with collections' do
    let!(:collection1) { create(:public_collection, title: 'Red') }
    let!(:collection2) do
      create(:public_collection, title: 'Pink',
                                 id: 'fk/4v/98/9d/fk4v989d9j',
                                 identifier: ['ark:/99999/fk4v989d9j'],
                                 extent: ['7 photos'])
    end

    scenario 'Search for a collection' do
      visit collections.collections_path

      fill_in 'q', with: 'Pink'
      click_button 'Search'
      expect(page).not_to have_content 'Red'
      click_link 'Pink'

      # View collection metadata
      expect(page).to have_content 'Pink'
      expect(page).to have_content '7 photos'
    end
  end

  context 'collections with images' do
    before do
      Collection.destroy_all
      Image.destroy_all
    end

    let(:pink)   { { title: 'Pink',   identifier: ['pink']   } }
    let(:orange) { { title: 'Orange', identifier: ['orange'] } }
    let(:banana) { { title: 'Banana', identifier: ['banana'] } }

    let(:colors_attrs) { { title: 'Colors' } }
    let(:fruits_attrs) { { title: 'Fruits' } }

    let!(:colors) { create_collection_with_images(colors_attrs, [pink, orange]) }
    let!(:fruits) { create_collection_with_images(fruits_attrs, [orange, banana]) }

    scenario 'Search within a collection' do
      visit collections.collection_path(colors)

      expect(page).to have_selector('#documents .document', count: 2)
      expect(page).to have_link('Pink', href: '/lib/pink')
      expect(page).to have_link('Orange', href: '/lib/orange')
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
      expect(page).to have_link('Orange', href: '/lib/orange')
      expect(page).to_not have_link('Banana', href: '/lib/banana')
    end

    scenario 'Search with the main search bar instead of within the collection' do
      visit collections.collection_path(colors)

      expect(page).to have_selector('#documents .document', count: 2)
      expect(page).to have_link('Pink', href: '/lib/pink')
      expect(page).to have_link('Orange', href: '/lib/orange')
      expect(page).to_not have_link('Banana', href: '/lib/banana')

      # Search for something that's not in this collection
      fill_in 'q', with: banana[:title]
      click_button 'search'

      expect(page).to have_selector('#documents .document', count: 1)
      expect(page).to_not have_link('Pink', href: '/lib/pink')
      expect(page).to_not have_link('Orange', href: '/lib/orange')
      expect(page).to have_link('Banana', href: '/lib/banana')
    end
  end
end
