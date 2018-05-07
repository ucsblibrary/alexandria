# frozen_string_literal: true

require "rails_helper"

describe "MapSet show page:" do
  before do
    [index_map_west_id,
     index_map_east_id,
     component_map_river_id,
     component_map_city_id,].each do |id|
      if ActiveFedora::Base.exists?(id)
        ActiveFedora::Base.find(id).destroy(eradicate: true)
      end
    end

    VCR.use_cassette("show_map_set_feature_spec") do
      index_map_west.ordered_members << file_set
      index_map_west.save
      index_map_east.ordered_members << file_set
      index_map_east.save

      component_map_river.ordered_members << file_set
      component_map_river.save
      component_map_city.ordered_members << file_set
      component_map_city.save

      map_set.update_index
    end
  end

  let(:title) { ["Japan 1:250,000"] }
  let(:scale) { ["approximately 1:300,000"] }
  let(:extent) { ["maps : color ; 47 x 71 cm or smaller"] }
  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }

  let(:creator_uri) do
    RDF::URI.new("http://id.loc.gov/authorities/names/n79122611")
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

  let(:collection) do
    create(:public_collection,
           identifier: ["ark:/99999/weh"],
           title: ["My Maps"])
  end

  let(:index_collection) do
    create(:public_collection,
           identifier: ["ark:/99999/wehhhh"],
           title: ["Index Maps"])
  end

  let(:map_set) do
    MapSet.create(
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      identifier: ["ark:/99999/guh"],
      index_map_id: %w[east west],
      creator: [creator_uri],
      extent: extent,
      local_collection_id: [collection.id],
      scale: scale,
      title: title
    )
  end

  let(:index_map_west_id) { "index_map_west" }
  let(:index_map_west) do
    IndexMap.create(
      accession_number: ["west"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      id: index_map_west_id,
      identifier: ["ark:/99999/#{index_map_west_id}"],
      local_collection_id: [index_collection.id],
      parent_id: map_set.id,
      title: ["Index Map, West Side"]
    )
  end

  let(:index_map_east_id) { "index_map_east" }
  let(:index_map_east) do
    IndexMap.create(
      accession_number: ["east"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      id: index_map_east_id,
      identifier: ["ark:/99999/#{index_map_east_id}"],
      local_collection_id: [index_collection.id],
      parent_id: map_set.id,
      title: ["Index Map, East Side"]
    )
  end

  let(:component_map_river_id) { "component_map_river" }
  let(:component_map_river) do
    ComponentMap.create(
      accession_number: ["river"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      alternative: ["river"],
      id: component_map_river_id,
      identifier: ["ark:/99999/#{component_map_river_id}"],
      local_collection_id: [collection.id],
      parent_id: map_set.id,
      title: ["Component Map of the River Area"]
    )
  end

  let(:component_map_city_id) { "component_map_city" }
  let(:component_map_city) do
    ComponentMap.create(
      accession_number: ["city"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      alternative: ["city"],
      id: component_map_city_id,
      identifier: ["ark:/99999/#{component_map_city_id}"],
      local_collection_id: [collection.id],
      parent_id: map_set.id,
      title: ["Component Map of the City Area"]
    )
  end

  it "show the page" do
    visit catalog_ark_path("ark:", "99999", map_set.id)
    expect(page).to have_content title.first
    expect(page).to have_content extent.first
    # de-referenced creator
    expect(page).to have_content "United States. Army Map Service"
    expect(page).to have_content scale.first

    expect(page).to have_content "Index Maps"
    expect(page).to(
      have_link("Index Map, East Side",
                href: catalog_ark_path("ark:", "99999", index_map_east.id))
    )

    expect(page).to(
      have_link("Index Map, West Side",
                href: catalog_ark_path("ark:", "99999", index_map_west.id))
    )

    expect(page).to have_content "Map Sheets"
    expect(page).to(
      have_link("city",
                href: catalog_ark_path("ark:", "99999", component_map_city.id))
    )
    expect(page).to(
      have_link("river",
                href: catalog_ark_path("ark:", "99999", component_map_river.id))
    )

    # The thumbnail should be a link to the show page for that
    # record.
    click_link("Index Map, West Side")
    expect(page).to have_content index_map_west.title.first

    # Now we're on the show page for the West Index Map. The 0th
    # thumbnail for the component maps should be the City map.
    click_link("city")
    expect(page).to have_content component_map_city.title.first
  end
end
