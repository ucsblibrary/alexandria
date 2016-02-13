require 'rails_helper'

describe "Browsing by Type of Resource" do
  before do
    VCR.use_cassette('resource_type_text') do
      create :public_etd, work_type: [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')]
    end
  end

  specify do
    visit root_path
    click_on 'Format'
    expect(page).to have_link 'Text', href: search_catalog_path(f: { work_type_label_sim: ['Text'] })
  end
end
