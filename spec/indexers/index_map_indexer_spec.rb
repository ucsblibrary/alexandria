# frozen_string_literal: true

require "rails_helper"

describe IndexMapIndexer do
  before do
    IndexMap.all.map(&:id).each do |id|
      if ActiveFedora::Base.exists?(id)
        ActiveFedora::Base.find(id).destroy(eradicate: true)
      end
    end
  end
  subject { described_class.new(index_map).generate_solr_document }

  context "with a file_set" do
    let(:file) do
      double(
        id: "s1/78/4k/72/s1784k724/files/6185235a-79b2-4c29-8c24-4d6ad9b11470"
      )
    end
    let(:file_set) { double(files: [file]) }

    before do
      allow(index_map).to receive_messages(file_sets: [file_set])
    end
    let(:index_map) { IndexMap.new }

    it "has images" do
      VCR.use_cassette("index_map_indexer") do
        expect(subject["square_thumbnail_url_ssm"]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/square/100,/0/default.jpg"]
        )

        expect(subject[ObjectIndexer.thumbnail_field]).to(
          eq ["/image-service/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/300,/0/default.jpg"]
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
      end
    end
  end

  describe "Indexing dates" do
    context "with an issued date" do
      let(:index_map) { IndexMap.new(issued_attributes: [{ start: ["1902"] }]) }

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1902"
      end
    end

    context "with an copyrighted date" do
      let(:copyrighted) { ["1913"] }

      let(:index_map) do
        IndexMap.new(date_copyrighted_attributes: [{ start: copyrighted }])
      end

      it "indexes dates for display" do
        expect(subject["date_copyrighted_ssm"]).to eq copyrighted
      end
    end

    context "with issued.start and issued.finish" do
      let(:issued_start) { ["1917"] }
      let(:issued_end) { ["1923"] }
      let(:index_map) do
        IndexMap.new(
          issued_attributes: [{ start: issued_start, finish: issued_end }]
        )
      end

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1917 - 1923"
      end
    end
  end

  context "with work type" do
    let(:work_type) do
      RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/img")
    end
    let(:index_map) { IndexMap.new(work_type: [work_type]) }

    it "indexes a label" do
      VCR.use_cassette("index_map_resource_type") do
        expect(subject["work_type_sim"]).to eq [work_type]
        expect(subject["work_type_label_sim"]).to eq ["Still Image"]
        expect(subject["work_type_label_tesim"]).to eq ["Still Image"]
      end
    end
  end

  context "with location" do
    let(:location) do
      RDF::URI("http://id.loc.gov/authorities/subjects/sh85072779")
    end
    let(:index_map) { IndexMap.new(location: [location]) }

    it "indexes a label" do
      VCR.use_cassette("index_map_indexer") do
        expect(subject["location_sim"]).to eq [location]
        expect(subject["location_label_sim"]).to eq ["Kodiak Island (Alaska)"]
        expect(subject["location_label_tesim"]).to eq ["Kodiak Island (Alaska)"]
      end
    end
  end

  context "with local and LOC rights holders" do
    let(:regents_uri) do
      RDF::URI("http://id.loc.gov/authorities/names/n85088322")
    end
    let(:valerie) { Agent.create(foaf_name: "Valerie") }
    let(:valerie_uri) { RDF::URI(valerie.uri) }

    let(:index_map) { IndexMap.new(rights_holder: [valerie_uri, regents_uri]) }

    before do
      AdminPolicy.ensure_admin_policy_exists
    end

    it "indexes with a label" do
      VCR.use_cassette("index_map_indexer2") do
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
