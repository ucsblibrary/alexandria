# frozen_string_literal: true

require "rails_helper"

describe "map routes" do
  let(:id) { "fk41234567" }

  before do
    if ActiveFedora::Base.exists? id
      ActiveFedora::Base.find(id).destroy(eradicate: true)
    end
  end

  context "ScannedMap" do
    before do
      create(:public_scanned_map, identifier: ["ark:/99999/#{id}"], id: id)
    end

    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "catalog",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
  context "IndexMap" do
    before do
      create(:public_index_map, identifier: ["ark:/99999/#{id}"], id: id)
    end

    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "catalog",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
  context "ComponentMap" do
    before do
      create(:public_component_map, identifier: ["ark:/99999/#{id}"], id: id)
    end

    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "catalog",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end

  context "MapSet" do
    before do
      create(:public_map_set, identifier: ["ark:/99999/#{id}"], id: id)
    end

    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "catalog",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
end
