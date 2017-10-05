# coding: utf-8
# frozen_string_literal: true

require "active_fedora/cleaner"
require "rails_helper"
require "importer"
require "parse"

describe Importer::CSV do
  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists
  end

  let(:data) { Dir["#{fixture_path}/images/*"] }
  let(:logger) { Logger.new(STDOUT) }

  context "map parent data" do
    let(:map_set_accession_number) { ["4450s 250 b7"] }
    let(:index_map_accession_number) { ["4450s 250 b7 index"] }

    let!(:map_set_attrs) do
      { accession_number: map_set_accession_number,
        title: ["Carta do Brasil"], }
    end

    let!(:index_map_attrs) do
      { accession_number: index_map_accession_number,
        title: ["Index Map do Brasil"], }
    end

    let(:structural_metadata) do
      { parent_accession_number: map_set_accession_number,
        index_map_accession_number: index_map_accession_number, }
    end

    it "can return a map set's id when given an accession_number" do
      VCR.use_cassette("csv_importer") do
        map_set = Importer::Factory::MapSetFactory.new(map_set_attrs).run

        expect(
          Parse::CSV.get_id_for_accession_number(
            map_set_attrs[:accession_number]
          )
        ).to eql(map_set.id)
      end
    end

    it "can return an index map's id when given an accession_number" do
      VCR.use_cassette("csv_importer") do
        index_map = Importer::Factory::IndexMapFactory.new(index_map_attrs).run

        expect(
          Parse::CSV.get_id_for_accession_number(
            index_map_attrs[:accession_number]
          )
        ).to eql(index_map.id)
      end
    end

    it "attaches an index map to its map set" do
      VCR.use_cassette("csv_importer") do
        map_set = Importer::Factory::MapSetFactory.new(map_set_attrs).run

        expect(
          Parse::CSV.handle_structural_metadata(
            structural_metadata
          )[:parent_id]
        ).to eql(map_set.id)
      end
    end
  end

  context "all maps are imported and map set is reindexed" do
    before do
      VCR.use_cassette("csv_map_set_importer") do
        described_class.import(
          meta: ["#{fixture_path}/csv/fake_brazil_data.csv"],
          data: Dir["#{fixture_path}/maps/*"],
          options: { skip: 0 }
        )
      end
    end

    let(:m) { MapSet.first }

    it "creates all expected objects" do
      expect(Collection.count).to eq(1)
      expect(MapSet.count).to eq(1)
      expect(IndexMap.count).to eq(1)
      expect(ComponentMap.count).to eq(2)
    end

    it "attaches objects as expected" do
      expect(m.index_maps.size).to eq(1)
      expect(m.component_maps.size).to eq(2)
    end

    it "reindexes the map set after its members are imported" do
      r = ActiveFedora::SolrService.query("id:#{m.id}")
      expect(r.first["index_maps_ssim"].size).to eq(1)
      expect(r.first["component_maps_ssim"].size).to eq(2)
    end
  end

  context "when the model is specified" do
    let(:metadata) { ["#{fixture_path}/csv/pamss045.csv"] }

    it "creates a new image" do
      VCR.use_cassette("csv_importer") do
        described_class.import(
          meta: metadata,
          data: data,
          options: { skip: 0 },
          logger: logger
        )
      end
      expect(Image.count).to eq(1)

      img = Image.first
      expect(img.title).to eq ["Dirge for violin and piano (violin part)"]
      expect(img.file_sets.count).to eq 4

      expect(
        img.file_sets.map do |d|
          d.files.map { |f| f.file_name.first }
        end.flatten
      ).to(
        contain_exactly("dirge1.tif",
                        "dirge2.tif",
                        "dirge3.tif",
                        "dirge4.tif")
      )

      expect(img.in_collections.first.title).to eq(["Mildred Couper papers"])
      expect(img.license.first.rdf_label).to(
        eq ["http://rightsstatements.org/vocab/InC/1.0/"]
      )
    end
  end
end
