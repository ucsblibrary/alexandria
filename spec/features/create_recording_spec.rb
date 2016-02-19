require 'rails_helper'

describe 'Creating a new Recording' do
  let(:user) { FactoryGirl.create(:admin) }

  before do
    login_as user
  end

  specify 'creating a work without a file' do
    visit '/concern/audio_recordings/new'
    fill_in('Title', with: 'My Test Work')
    click_on('Create Audio recording')
    expect(page).to have_content('My Test Work (Audio Recording)')
  end
end
