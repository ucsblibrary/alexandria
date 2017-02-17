# frozen_string_literal: true
require "rails_helper"

describe "map routes" do
  let(:id) { "fk41234567" }
  before do
    ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists? id
  end
  context "ScannedMap" do
    before { create(:public_scanned_map, identifier: ["ark:/99999/#{id}"], id: id) }
    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "curation_concerns/scanned_maps",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
  context "IndexMap" do
    before { create(:public_index_map, identifier: ["ark:/99999/#{id}"], id: id) }
    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "curation_concerns/index_maps",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
  context "ComponentMap" do
    before { create(:public_component_map, identifier: ["ark:/99999/#{id}"], id: id) }
    it "finds the correct controller" do
      expect(get: "/lib/ark:/99999/#{id}")
        .to route_to(
          controller: "curation_concerns/component_maps",
          prot: "ark:",
          shoulder: "99999",
          action: "show",
          id: id
        )
    end
  end
end
