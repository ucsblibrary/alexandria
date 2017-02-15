# frozen_string_literal: true
require "rails_helper"

describe "routes to ScannedMap" do
  let(:id) { "fk41234567" }
  let!(:map) { create(:public_scanned_map, identifier: ["ark:/99999/#{id}"], id: id) }
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
