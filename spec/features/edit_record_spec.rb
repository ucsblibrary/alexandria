require 'rails_helper'

feature 'Editing Records:' do
  let(:record) { Topic.create(label: ['old label']) }
  let(:new_label) { 'New label' }

  context 'an admin user' do
    let(:admin) { create :admin }

    before do
      AdminPolicy.ensure_admin_policy_exists
      login_as admin
    end

    scenario 'edits a record' do
      visit catalog_path(record)
      click_link 'Edit Metadata'
      fill_in 'Label', with: new_label
      click_button 'Save'
      expect(page).to have_content new_label
      expect(record.reload.label).to eq [new_label]
    end
  end
end
