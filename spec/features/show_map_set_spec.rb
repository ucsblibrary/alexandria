# frozen_string_literal: true
require "rails_helper"

feature "MapSet show page:" do
  let(:title) { ["Japan 1:250,000"] }
  let(:scale) { ["approximately 1:300,000"] }
  let(:extent) { ["maps : color ; 47 x 71 cm or smaller"] }
  let(:creator) { "http://id.loc.gov/authorities/names/n79122611" }
  let(:creator_uri) { RDF::URI.new(creator) }
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
  let!(:index_map0) do
    FactoryGirl.create(:public_index_map, title: ["Index Map 0"], parent_id: map_set.id)
  end
  let!(:index_map1) do
    FactoryGirl.create(:public_index_map, title: ["Index Map 1"], parent_id: map_set.id)
  end
  let!(:component_map0) do
    FactoryGirl.create(:public_component_map, title: ["Component Map 0"], parent_id: map_set.id)
  end

  before do
    index_map0.members << file_set
    index_map1.members << file_set
    index_map0.save
    index_map1.save
    component_map0.members << file_set
    component_map0.save
    # puts index_map.resource.dump(:ttl)
    # puts map_set.resource.dump(:ttl)
    index_map0.update_index
    index_map1.update_index
    component_map0.update_index
    map_set.update_index
  end

  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map_set.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "United States. Army Map Service" # de-referenced creator
    expect(page).to have_content scale.first
    expect(page).to have_link("indexmap0")
    expect(page).to have_link("indexmap1")
    expect(page).to have_link("componentmap0")
    click_link("indexmap1")
    expect(page).to have_content "Index Map 1"
  end
end
