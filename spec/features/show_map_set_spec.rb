# frozen_string_literal: true

require "rails_helper"

feature "MapSet show page:" do
  let(:title) { ["Japan 1:250,000"] }
  let(:scale) { ["approximately 1:300,000"] }
  let(:extent) { ["maps : color ; 47 x 71 cm or smaller"] }
  let(:creator_uri) { RDF::URI.new("http://id.loc.gov/authorities/names/n79122611") }
  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }
  let(:policy_id) { AdminPolicy::PUBLIC_POLICY_ID }
  let(:file_set) do
    FileSet.new(admin_policy_id: policy_id) do |fs|
      Hydra::Works::AddFileToFileSet.call(fs, File.new(file_path), :original_file)
    end
  end
  let(:map_set) do
    VCR.use_cassette("show_map_set_feature_spec") do
      FactoryGirl.create(:public_map_set, title: title, scale: scale, extent: extent, creator: [creator_uri])
    end
  end

  let(:index_map_west_id) { "index_map_west" }
  let(:index_map_west) do
    FactoryGirl.create(:public_index_map, id: index_map_west_id, title: ["Index Map, West Side"], parent_id: map_set.id, accession_number: ["west"], identifier: ["ark:/99999/#{index_map_west_id}"])
  end

  let(:index_map_east_id) { "index_map_east" }
  let(:index_map_east) do
    FactoryGirl.create(:public_index_map, id: index_map_east_id, title: ["Index Map, East Side"], parent_id: map_set.id, accession_number: ["east"], identifier: ["ark:/99999/#{index_map_east_id}"])
  end

  let(:component_map_river_id) { "component_map_river" }
  let(:component_map_river) do
    FactoryGirl.create(:public_component_map, id: component_map_river_id, title: ["Component Map of the River Area"], parent_id: map_set.id, accession_number: ["river"], identifier: ["ark:/99999/#{component_map_river_id}"])
  end

  let(:component_map_city_id) { "component_map_city" }
  let(:component_map_city) do
    FactoryGirl.create(:public_component_map, id: component_map_city_id, title: ["Component Map of the City Area"], parent_id: map_set.id, accession_number: ["city"], identifier: ["ark:/99999/#{component_map_city_id}"])
  end

  before do
    [index_map_west_id, index_map_east_id, component_map_river_id, component_map_city_id].each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end

    index_map_west.members << file_set
    index_map_west.save
    index_map_east.members << file_set
    index_map_east.save

    component_map_river.members << file_set
    component_map_river.save
    component_map_city.members << file_set
    component_map_city.save

    map_set.update_index
  end

  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map_set.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "United States. Army Map Service" # de-referenced creator
    expect(page).to have_content scale.first

    # The index and component maps should appear in order of
    # accession number
    expect(page).to have_link("indexmap0", href: catalog_ark_path("ark:", "99999", index_map_east.id))
    expect(page).to have_link("indexmap1", href: catalog_ark_path("ark:", "99999", index_map_west.id))
    expect(page).to have_link("componentmap0", href: catalog_ark_path("ark:", "99999", component_map_city.id))
    expect(page).to have_link("componentmap1", href: catalog_ark_path("ark:", "99999", component_map_river.id))

    # The thumbnail should be a link to the show page for that
    # record.
    click_link("indexmap1")
    expect(page).to have_content index_map_west.title.first

    # Now we're on the show page for the West Index Map. The 0th
    # thumbnail for the component maps should be the City map.
    click_link("componentmap0")
    expect(page).to have_content component_map_city.title.first
  end
end
