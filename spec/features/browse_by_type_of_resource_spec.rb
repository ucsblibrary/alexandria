require 'rails_helper'

describe "Browsing by Type of Resource" do
  before do
    create :public_etd
  end

  specify do
    visit root_path
    click_on 'Format'
    expect(page).to have_link 'Text', href: search_catalog_path(f: { work_type_label_sim: ['Text'] })
  end
end
