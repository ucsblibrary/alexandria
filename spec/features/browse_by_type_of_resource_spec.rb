# frozen_string_literal: true

require "rails_helper"

feature "Browsing by Type of Resource" do
  before do
    VCR.use_cassette("browse_by_type_of_resource") do
      create(
        :public_etd,
        work_type: [
          RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/txt"),
        ]
      )
    end
  end

  specify do
    visit root_path
    click_on "Format"
    expect(page).to(
      have_link(
        "Text",
        href: search_catalog_path(f: { work_type_label_sim: ["Text"] })
      )
    )
  end
end
