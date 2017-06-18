# frozen_string_literal: true

require "rails_helper"

feature "ComponentMap show page:" do
  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }
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

  let(:map) do
    VCR.use_cassette("show_component_map_feature_spec") do
      ComponentMap.create(
        accession_number: ["7070 something"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        alternative: ["something"],
        creator: [creator_uri],
        extent: extent,
        index_map_id: ["north pole"],
        local_collection_id: [collection.id],
        parent_id: map_set.id,
        scale: scale,
        title: title
      )
    end
  end

  let!(:sibling_component_map) do
    ComponentMap.create(
      accession_number: ["7070 another thing"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      alternative: ["another thing"],
      index_map_id: ["north pole"],
      local_collection_id: [collection.id],
      parent_id: map_set.id,
      scale: ["Sibling's scale"],
      title: ["Sibling CM"]
    )
  end

  let!(:index_map) do
    IndexMap.create(
      accession_number: ["north pole"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      parent_id: map_set.id,
      title: ["Index Map 0"]
    )
  end

  let!(:map_set) do
    MapSet.create(
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      identifier: ["ark:/99999/bleh"],
      local_collection_id: [collection.id],
      title: ["Parent Map Set"]
    )
  end

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
    VCR.use_cassette("show_component_map_feature_spec") do
      map.save!
      index_map.members << file_set
      index_map.save!
      sibling_component_map.members << file_set
      sibling_component_map.save!
      map_set.update_index
    end
  end

  scenario "show the page" do
    visit catalog_ark_path("ark:", "99999", map.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    expect(page).to have_content "Century Company"
    expect(page).to have_content scale.first

    expect(page).to have_content "Index Maps"
    expect(page).to have_link "Index Map 0"

    expect(page).to have_content "Map Sheets"
    # The map tray doesn't link to itself
    expect(page).to have_content("something")
    expect(page).to have_link("another thing")

    expect(page).to(
      have_link(collection.title.first, collection_path(collection))
    )
    expect(page).to(
      have_link(map_set.title.first, curation_concerns_map_set_path(map_set))
    )
  end
end
