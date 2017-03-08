# frozen_string_literal: true
require "rails_helper"

feature "ComponentMap show page:" do
  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }
  let(:creator) { "http://id.loc.gov/authorities/names/n81038526" }
  let(:creator_uri) { RDF::URI.new(creator) }
  let(:title) { ["Region around the North Pole : giving the records of the most important explorations"] }
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }

  let(:map) do
    VCR.use_cassette("show_component_map_feature_spec") do
      FactoryGirl.create(:public_component_map, title: title, creator: [creator_uri], extent: extent, scale: scale, parent_id: map_set.id)
    end
  end

  let!(:sibling_component_map) do
    FactoryGirl.create(:public_component_map, title: ["Sibling CM"], scale: ["Sibling's scale"], parent_id: map_set.id)
  end

  let!(:index_map) do
    FactoryGirl.create(:public_index_map, title: ["Index Map 0"], parent_id: map_set.id)
  end

  let!(:map_set) do
    FactoryGirl.create(:public_map_set, title: ["Parent Map Set"])
  end

  let(:file_set) do
    FileSet.new(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID) do |fs|
      Hydra::Works::AddFileToFileSet.call(fs, File.new(file_path), :original_file)
    end
  end

  before do
    map.members << file_set
    map.save!
    index_map.members << file_set
    index_map.save!
    sibling_component_map.members << file_set
    sibling_component_map.save!
    map_set.update_index
  end

  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "Century Company"
    expect(page).to have_content scale.first

    expect(page).to have_link("indexmap0")
    expect(page).to have_link("componentmap0")
    expect(page).to have_link("componentmap1")
  end
end
