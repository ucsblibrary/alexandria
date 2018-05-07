# frozen_string_literal: true

require "rails_helper"

describe "IndexMap show page:" do
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }

  let(:creator_uri) do
    RDF::URI.new("http://id.loc.gov/authorities/names/n81038526")
  end

  let(:title) do
    ["Region around the North Pole : "\
     "giving the records of the most important explorations",]
  end

  let(:collection) do
    create(:public_collection,
           identifier: ["ark:/99999/weh"],
           title: ["My Maps"])
  end

  # This is the map whose show page we want to view
  let!(:map) do
    VCR.use_cassette("show_index_map_feature_spec") do
      IndexMap.create(
        accession_number: ["north pole"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        creator: [creator_uri],
        extent: extent,
        local_collection_id: [collection.id],
        parent_id: map_set.id,
        scale: scale,
        title: title
      )
    end
  end

  let!(:map_set) do
    MapSet.create(
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      title: ["Parent Map Set"],
      index_map_id: ["north pole"]
    )
  end

  let!(:component_map) do
    ComponentMap.create(
      accession_number: ["7070 CM0"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      alternative: ["7070 CM0"],
      index_map_id: ["north pole"],
      parent_id: map_set.id,
      title: ["CM0"]
    )
  end

  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }
  let(:file_set) do
    FileSet.new(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID) do |fs|
      Hydra::Works::AddFileToFileSet.call(
        fs,
        File.new(file_path),
        :original_file
      )
    end
  end

  before do
    # Need ARK to be able to draw thumbnail links
    allow_any_instance_of(SolrDocument).to receive(:ark).and_return("123")
    map.members << file_set
    VCR.use_cassette("show_index_map_feature_spec") do
      map.save!
      component_map.ordered_members << file_set
      component_map.save!
      map_set.update_index
    end
  end

  it "show the page" do
    visit catalog_ark_path("ark:", "99999", map.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "Century Company"
    expect(page).to have_content scale.first

    expect(page).to have_content "Map Sheets"
    expect(page).to have_link("7070 CM0")
  end
end
