# coding: utf-8
# frozen_string_literal: true

require "rails_helper"
require "importer"
require "active_fedora/cleaner"

describe Importer::CSV do
  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists

    described_class.log_location("#{fixture_path}/logs/csv_map_set_import.log")

    VCR.use_cassette("csv_map_set_importer") do
      described_class.import(
        ["#{fixture_path}/csv/fake_brazil_data.csv"],
        Dir["#{fixture_path}/maps/*"],
        skip: 0
      )
    end
  end

  context "all maps are imported and map set is reindexed" do
    let(:m) { MapSet.first }

    it "creates all expected objects" do
      expect(MapSet.count).to eq(1)
      expect(IndexMap.count).to eq(1)
      expect(ComponentMap.count).to eq(2)
    end

    it "attaches objects as expected" do
      expect(m.index_maps.size).to be(1)
      expect(m.component_maps.size).to be(2)
    end

    it "reindexes the map set after its members are imported" do
      r = ActiveFedora::SolrService.query("id:#{m.id}")
      expect(r.first["index_maps_ssim"].size).to be(1)
      expect(r.first["component_maps_ssim"].size).to be(2)
    end
  end
end
