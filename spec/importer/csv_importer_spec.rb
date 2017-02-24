# coding: utf-8
# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::CSV do
  before { Image.destroy_all }
  let(:logfile) { "#{fixture_path}/logs/csv_import.log" }
  before(:example) do
    Importer::CSV.log_location(logfile)
  end

  let(:data) { Dir["spec/fixtures/images/*"] }

  context "when the model is specified" do
    let(:metadata) { ["#{fixture_path}/csv/pamss045.csv"] }

    it "creates a new image" do
      VCR.use_cassette("csv_importer") do
        Importer::CSV.import(
          metadata, data, skip: 0
        )
      end
      expect(Image.count).to eq(1)

      img = Image.first
      expect(img.title).to eq ["Dirge for violin and piano (violin part)"]
      expect(img.file_sets.count).to eq 4
      expect(img.file_sets.map { |d| d.files.map(&:file_name) }.flatten)
        .to contain_exactly("dirge1.tif",
                            "dirge2.tif",
                            "dirge3.tif",
                            "dirge4.tif")
      expect(img.in_collections.first.title).to eq(["Mildred Couper papers"])
      expect(img.license.first.rdf_label).to eq ["In Copyright"]
    end
  end

  context "set access policy" do
    let(:public_data) { { access_policy: ["public"] } }
    it "assigns the public access policy if public is specified" do
      expect(Importer::CSV.assign_access_policy(public_data)).to eql(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end
    let(:ucsb_restricted_data) { { access_policy: ["ucsb"] } }
    it "assigns the UCSB restricted access policy" do
      expect(Importer::CSV.assign_access_policy(ucsb_restricted_data)).to eql(admin_policy_id: AdminPolicy::UCSB_POLICY_ID)
    end
    let(:discovery) { { access_policy: ["discovery"] } }
    it "assigns the discovery access policy" do
      expect(Importer::CSV.assign_access_policy(discovery)).to eql(admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID)
    end
    let(:public_campus) { { access_policy: ["public_campus"] } }
    it "assigns the public_campus policy" do
      expect(Importer::CSV.assign_access_policy(public_campus)).to eql(admin_policy_id: AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
    end
    let(:restricted) { { access_policy: ["restricted"] } }
    it "assigns the restricted policy" do
      expect(Importer::CSV.assign_access_policy(restricted)).to eql(admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID)
    end
    let(:ucsb_campus) { { access_policy: ["ucsb_campus"] } }
    it "assigns the ucsb_campus policy" do
      expect(Importer::CSV.assign_access_policy(ucsb_campus)).to eql(admin_policy_id: AdminPolicy::UCSB_CAMPUS_POLICY_ID)
    end
    let(:uc) { { access_policy: ["uc"] } }
    it "assigns the uc policy" do
      expect(Importer::CSV.assign_access_policy(uc)).to eql(admin_policy_id: AdminPolicy::UC_POLICY_ID)
    end
    # Per DIGREPO-728: If no access policy is specified in the CSV file, raise an error
    it "raises an error if there is no policy specified" do
      expect { Importer::CSV.assign_access_policy({}) }.to raise_error(RuntimeError, "No access policy defined")
    end
    let(:nonsense) { { access_policy: ["nonsense"] } }
    it "raises an error if an unrecognized value is given for the policy code" do
      expect { Importer::CSV.assign_access_policy(nonsense) }.to raise_error(RuntimeError, /Invalid access policy:/)
    end
  end

  context "format coordinates as DCMI box" do
    let(:in_process_data) do
      {
        west_bound_longitude: ["-74.0000"],
        east_bound_longitude: ["-34.0000"],
        north_bound_latitude: ["4.0000"],
        south_bound_latitude: ["-34.0000"],
      }
    end
    let(:dcmi_formatted_data) do
      {
        coverage: "northlimit=4.0000; eastlimit=-34.0000; southlimit=-34.0000; westlimit=-74.0000; units=degrees; projection=EPSG:4326",
      }
    end
    it "takes coordinate data and turns it into a DCMI box" do
      expect(Importer::CSV.transform_coordinates_to_dcmi_box(in_process_data)).to eql(dcmi_formatted_data)
    end
    it "does not error out if the file has no coordinates" do
      expect(Importer::CSV.transform_coordinates_to_dcmi_box({})).to eql({})
    end
    context "all components are optional" do
      let(:western_hemisphere_coordinates) do
        {
          west_bound_longitude: ["180"],
          east_bound_longitude: ["0"],
        }
      end
      let(:western_hemisphere_dcmi_formatted) do
        {
          coverage: "eastlimit=0; westlimit=180; units=degrees; projection=EPSG:4326",
        }
      end
      it "takes coordinate data and turns it into a DCMI box for only two values" do
        expect(Importer::CSV.transform_coordinates_to_dcmi_box(western_hemisphere_coordinates)).to eql(western_hemisphere_dcmi_formatted)
      end
    end
  end

  context "character encoding checks" do
    let(:csvfile) { "#{fixture_path}/csv/pamss045.csv" }
    it "reads in a known CSV file" do
      expect(Importer::CSV.split(csvfile)).to be_instance_of(Array)
    end

    let(:utf8problemfile) { "#{fixture_path}/csv/mcpeak-utf8problems.csv" }
    it "reads in a CSV file with UTF-8 problems" do
      expect(Importer::CSV.split(utf8problemfile)).to be_instance_of(Array)
    end

    # Sometimes we encounter CSV input files with BOM characters
    # See https://en.wikipedia.org/wiki/Byte_order_mark for more info
    # You have to read in BOM files with encoding: "bom|UTF-8"
    let(:bomproblemfile) { "#{fixture_path}/csv/bom_encoded_file.csv" }
    let(:split) { Importer::CSV.split(bomproblemfile) }
    let(:attrs) { Importer::CSV.csv_attributes(split[0], split[1][0]) }
    it "handles bom encoding" do
      expect(attrs[:type]).to eql("Map set")
    end

    let(:brazilmap) { "#{fixture_path}/csv/brazil.csv" }
    # DIGREPO-676 Row 4 title should read as "Rio Xixé" with an accent over the final e.
    it "reads in diacritics properly" do
      expect(Importer::CSV.split(brazilmap)).to be_instance_of(Array)
      a = Importer::CSV.split(brazilmap)
      expect(a[1][2][3]).to eql("Rio Xixé")
    end
  end

  context "determine model" do
    it "returns ScannedMap when the model value is 'Scanned map'" do
      expect(Importer::CSV.determine_model("Scanned map")).to eql("ScannedMap")
    end
    it "returns ScannedMap when the model value is 'ScannedMap'" do
      expect(Importer::CSV.determine_model("ScannedMap")).to eql("ScannedMap")
    end
    it "returns Image when the model value is 'image'" do
      expect(Importer::CSV.determine_model("image")).to eql("Image")
    end
    it "returns IndexMap when the model value is 'index Map'" do
      expect(Importer::CSV.determine_model("index Map")).to eql("IndexMap")
    end
  end

  context "map parent data" do
    before do
      @map_set_accession_number = ["4450s 250 b7"]
      @index_map_accession_number = ["4450s 250 b7 index"]
      @structural_metadata =
        {
          parent_accession_number: @map_set_accession_number,
          index_map_accession_number: @index_map_accession_number,
        }
      @map_set_attrs = { accession_number: @map_set_accession_number, title: ["Carta do Brasil"] }
      VCR.use_cassette("map_set_factory2") do
        @map_set = Importer::Factory::MapSetFactory.new(@map_set_attrs).run
      end
      @index_map_attrs = { accession_number: @index_map_accession_number, title: ["Index Map do Brasil"] }
      VCR.use_cassette("index_map_factory2") do
        @index_map = Importer::Factory::IndexMapFactory.new(@index_map_attrs).run
      end
      @goal_state =
        {
          parent_id: @map_set.id,
          # a map set can contain many index maps,
          # so index_map_id must be an Array because of the way the field is defined
          index_map_id: [@index_map.id],
        }
    end
    it "doesn't throw any errors if these fields don't exist" do
      expect(Importer::CSV.handle_structural_metadata({})).to eql({})
    end
    it "can return a map set's id when given an accession_number" do
      expect(Importer::CSV.get_id_for_accession_number(@map_set_attrs[:accession_number])).to eql(@map_set.id)
    end
    it "can return an index map's id when given an accession_number" do
      expect(Importer::CSV.get_id_for_accession_number(@index_map_attrs[:accession_number])).to eql(@index_map.id)
    end
    it "returns nil when it can't find an id for a given accession_number" do
      expect(Importer::CSV.get_id_for_accession_number("foobar")).to eql(nil)
    end
    it "attaches an index map to its map set" do
      expect(Importer::CSV.handle_structural_metadata(@structural_metadata)[:parent_id]).to eql(@goal_state[:parent_id])
    end
    it "attaches a component map to its index map" do
      expect(Importer::CSV.handle_structural_metadata(@structural_metadata)[:index_map_id]).to eql(@goal_state[:index_map_id])
    end
  end

  # Sometimes exta spaces get into import CSVs. Strip them out.
  context "extra spaces in CSV" do
    let(:import_metdata) do
      { :"license " => ["public"],
        parent_title: ["Carta do Brasil"], }
    end
    let(:stripped) { Importer::CSV.strip_extra_spaces(import_metdata) }
    it "strips any extra spaces off of field names" do
      expect(stripped.keys.first.to_s).to eq "license"
    end
  end
end
