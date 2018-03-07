# frozen_string_literal: true

require "rails_helper"

describe ComponentMapIndexer do
  before do
    ComponentMap.all.map(&:id).each do |id|
      if ActiveFedora::Base.exists?(id)
        ActiveFedora::Base.find(id).destroy(eradicate: true)
      end
    end
  end
  subject { described_class.new(component_map).generate_solr_document }

  context "with a file_set" do
    let(:component_map) { ComponentMap.new }
    let(:file_set) do
      instance_double("FileSet", files: [file], image?: true)
    end

    let(:file) do
      instance_double(
        "ActiveFedora::File",
        id: "s1/78/4k/72/s1784k724/files/6185235a-79b2-4c29-8c24-4d6ad9b11470"
      )
    end

    before do
      allow(component_map).to receive_messages(file_sets: [file_set])
    end

    it "has images and iiif manifests" do
      VCR.use_cassette("component_map_indexer") do
        # rubocop:disable Metrics/LineLength
        expect(subject["square_thumbnail_url_ssm"]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/square/100,/0/default.jpg"]
        )

        expect(subject[ObjectIndexer.thumbnail_field]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/square/100,/0/default.jpg"]
        )

        expect(subject["image_url_ssm"]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/400,/0/default.jpg"]
        )

        expect(subject["large_image_url_ssm"]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/1000,/0/default.jpg"]
        )

        expect(subject["file_set_iiif_manifest_ssm"]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/info.json"]
        )
        # rubocop:enable Metrics/LineLength
      end
    end
  end

  describe "Indexing dates" do
    context "with an issued date" do
      let(:component_map) do
        ComponentMap.new(issued_attributes: [{ start: ["1902"] }])
      end

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1902"
      end
    end

    context "with a copyrighted date" do
      let(:copyrighted) { ["1913"] }
      let(:component_map) do
        ComponentMap.new(date_copyrighted_attributes: [{ start: copyrighted }])
      end

      it "indexes dates for display" do
        expect(subject["date_copyrighted_ssm"]).to eq copyrighted
      end
    end

    context "with issued.start and issued.finish" do
      let(:issued_start) { ["1917"] }
      let(:issued_end) { ["1923"] }
      let(:component_map) do
        ComponentMap.new(
          issued_attributes: [{ start: issued_start, finish: issued_end }]
        )
      end

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1917 - 1923"
      end
    end
  end

  context "with work type" do
    let(:component_map) { ComponentMap.new(work_type: [work_type]) }
    let(:work_type) do
      RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/img")
    end

    it "indexes a label" do
      VCR.use_cassette("component_map_resource_type") do
        expect(subject["work_type_sim"]).to eq [work_type]
        expect(subject["work_type_label_sim"]).to eq ["Still Image"]
        expect(subject["work_type_label_tesim"]).to eq ["Still Image"]
      end
    end
  end

  context "with location" do
    let(:component_map) { ComponentMap.new(location: [location]) }
    let(:location) do
      RDF::URI("http://id.loc.gov/authorities/subjects/sh85072779")
    end

    it "indexes a label" do
      VCR.use_cassette("component_map_indexer") do
        expect(subject["location_sim"]).to eq [location]
        expect(subject["location_label_sim"]).to eq ["Kodiak Island (Alaska)"]
        expect(subject["location_label_tesim"]).to eq ["Kodiak Island (Alaska)"]
      end
    end
  end

  context "with local and LOC rights holders" do
    let(:valerie) { Agent.create(foaf_name: "Valerie") }
    let(:valerie_uri) { RDF::URI(valerie.uri) }

    let(:regents_uri) do
      RDF::URI("http://id.loc.gov/authorities/names/n85088322")
    end

    let(:component_map) do
      ComponentMap.new(rights_holder: [valerie_uri, regents_uri])
    end

    before do
      AdminPolicy.ensure_admin_policy_exists
    end

    it "indexes with a label" do
      VCR.use_cassette("component_map_indexer_with_label") do
        expect(subject["rights_holder_ssim"]).to(
          contain_exactly(valerie_uri, regents_uri)
        )
        expect(subject["rights_holder_label_tesim"]).to(
          contain_exactly("Valerie",
                          "University of California (System). Regents")
        )
      end
    end
  end
end
