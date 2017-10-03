# coding: utf-8
# frozen_string_literal: true

require "rails_helper"
require "parse"

describe Parse::CSV do
  context "set access policy" do
    let(:public_data) { { access_policy: ["public"] } }
    it "assigns the public access policy if public is specified" do
      expect(described_class.assign_access_policy(public_data)).to(
        eql(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
      )
    end

    let(:ucsb_restricted_data) { { access_policy: ["ucsb"] } }
    it "assigns the UCSB restricted access policy" do
      expect(described_class.assign_access_policy(ucsb_restricted_data)).to(
        eql(admin_policy_id: AdminPolicy::UCSB_POLICY_ID)
      )
    end

    let(:discovery) { { access_policy: ["discovery"] } }
    it "assigns the discovery access policy" do
      expect(described_class.assign_access_policy(discovery)).to(
        eql(admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID)
      )
    end

    let(:public_campus) { { access_policy: ["public_campus"] } }
    it "assigns the public_campus policy" do
      expect(described_class.assign_access_policy(public_campus)).to(
        eql(admin_policy_id: AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
      )
    end

    let(:restricted) { { access_policy: ["restricted"] } }
    it "assigns the restricted policy" do
      expect(described_class.assign_access_policy(restricted)).to(
        eql(admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID)
      )
    end

    let(:ucsb_campus) { { access_policy: ["ucsb_campus"] } }
    it "assigns the ucsb_campus policy" do
      expect(described_class.assign_access_policy(ucsb_campus)).to(
        eql(admin_policy_id: AdminPolicy::UCSB_CAMPUS_POLICY_ID)
      )
    end

    # Per DIGREPO-728: If no access policy is specified in the CSV
    # file, raise an error
    it "raises an error if there is no policy specified" do
      expect { described_class.assign_access_policy({}) }.to(
        raise_error(RuntimeError, "No access policy defined")
      )
    end

    let(:nonsense) { { access_policy: ["nonsense"] } }

    it "raises an error for an unrecognized value" do
      expect { described_class.assign_access_policy(nonsense) }.to(
        raise_error(RuntimeError, /Invalid access policy:/)
      )
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
        coverage: "northlimit=4.0000; "\
                  "eastlimit=-34.0000; "\
                  "southlimit=-34.0000; "\
                  "westlimit=-74.0000; "\
                  "units=degrees; "\
                  "projection=EPSG:4326",
      }
    end

    it "takes coordinate data and turns it into a DCMI box" do
      expect(
        described_class.transform_coordinates_to_dcmi_box(in_process_data)
      ).to eql(dcmi_formatted_data)
    end

    it "does not error out if the file has no coordinates" do
      expect(described_class.transform_coordinates_to_dcmi_box({})).to eql({})
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
          coverage: "eastlimit=0; "\
                    "westlimit=180; "\
                    "units=degrees; "\
                    "projection=EPSG:4326",
        }
      end

      it "turns coordinate data into a DCMI box for only two values" do
        expect(
          described_class.transform_coordinates_to_dcmi_box(
            western_hemisphere_coordinates
          )
        ).to eql(western_hemisphere_dcmi_formatted)
      end
    end
  end

  context "determine model" do
    it "returns ScannedMap when the model value is 'Scanned map'" do
      expect(described_class.determine_model("Scanned map")).to(
        eql("ScannedMap")
      )
    end
    it "returns ScannedMap when the model value is 'ScannedMap'" do
      expect(described_class.determine_model("ScannedMap")).to eql("ScannedMap")
    end
    it "returns Image when the model value is 'image'" do
      expect(described_class.determine_model("image")).to eql("Image")
    end
    it "returns IndexMap when the model value is 'index Map'" do
      expect(described_class.determine_model("index Map")).to eql("IndexMap")
    end
  end

  context "map parent data" do
    let(:index_map_accession_number) { ["4450s 250 b7 index"] }
    let(:map_set_accession_number) { ["4450s 250 b7"] }
    let(:structural_metadata) do
      { parent_accession_number: map_set_accession_number,
        index_map_accession_number: index_map_accession_number, }
    end

    it "doesn't throw any errors if these fields don't exist" do
      expect(described_class.handle_structural_metadata({})).to eql({})
    end

    it "returns nil when it can't find an id for a given accession_number" do
      expect(described_class.get_id_for_accession_number("foobar")).to eq(nil)
    end

    it "attaches a component map to its index map" do
      expect(
        described_class.handle_structural_metadata(
          structural_metadata
        )[:index_map_id]
      ).to eql(index_map_accession_number)
    end
  end

  # Sometimes exta spaces get into import CSVs. Strip them out.
  context "extra spaces in CSV" do
    let(:import_metdata) do
      { "license ": ["public"],
        parent_title: ["Carta do Brasil"], }
    end

    let(:stripped) { described_class.strip_extra_spaces(import_metdata) }

    it "strips any extra spaces off of field names" do
      expect(stripped.keys.first.to_s).to eq "license"
    end
  end
end
