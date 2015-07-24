require 'rails_helper'

feature 'Local Authorities' do
  let(:admin) { create :admin }

  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists
    login_as admin
  end

  context 'with some records' do
    let!(:frodo) { create :person, foaf_name: 'Frodo Baggins' }
    let!(:fellows) { create :group, foaf_name: 'The Fellowship' }

    scenario 'browse using facets' do
      visit local_authorities_path
      click_button 'Search'

      expect(page).to have_link(frodo.foaf_name)
      expect(page).to have_link(fellows.foaf_name)

      within '#facets' do
        click_link 'Person'
      end

      expect(page).to     have_link(frodo.foaf_name)
      expect(page).to_not have_link(fellows.foaf_name)

      # Remove the previous facet selection
      within '#facets' do
        find('a.remove').click
      end

      expect(page).to have_link(frodo.foaf_name)
      expect(page).to have_link(fellows.foaf_name)

      within '#facets' do
        click_link 'Group'
      end

      expect(page).to_not have_link(frodo.foaf_name)
      expect(page).to     have_link(fellows.foaf_name)
    end


    scenario 'Click show link from index page' do
      visit local_authorities_path
      click_button 'Search'
      expect(page).to have_link(frodo.foaf_name)
      click_link frodo.foaf_name
      expect(page).to have_content("FOAF Name: #{frodo.foaf_name}")
    end
  end

end
