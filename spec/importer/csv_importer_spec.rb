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
    let(:ucsb_restricted_data) { { access_policy: ["ucsb"] } }
    it "assigns the public access policy if public is specified" do
      expect(Importer::CSV.assign_access_policy(public_data)).to eql(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end
    it "assigns the public access policy if there is no policy specified" do
      expect(Importer::CSV.assign_access_policy({})).to eql(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end
    it "assigns the UCSB restricted access policy" do
      expect(Importer::CSV.assign_access_policy(ucsb_restricted_data)).to eql(admin_policy_id: AdminPolicy::UCSB_POLICY_ID)
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

  context "#split" do
    let(:csvfile) { "#{fixture_path}/csv/pamss045.csv" }
    let(:utf8problemfile) { "#{fixture_path}/csv/mcpeak-utf8problems.csv" }

    it "reads in a known CSV file" do
      expect(Importer::CSV.split(csvfile)).to be_instance_of(Array)
    end

    it "reads in a CSV file with UTF-8 problems" do
      expect(Importer::CSV.split(utf8problemfile)).to be_instance_of(Array)
    end

    let(:brazilmap) { "#{fixture_path}/csv/brazil.csv" }
    # DIGREPO-676 Row 4 title should read as "Rio Xixé" with an accent over the final e.
    it "reads in diacritics properly" do
      expect(Importer::CSV.split(brazilmap)).to be_instance_of(Array)
      a = Importer::CSV.split(brazilmap)
      expect(a[1][2][3]).to eql("Rio Xixé")
    end
  end
end
