# frozen_string_literal: true

require "rails_helper"
require "importer"

describe ImageIndexer do
  before do
    Image.all.map(&:id).each do |id|
      if ActiveFedora::Base.exists?(id)
        ActiveFedora::Base.find(id).destroy(eradicate: true)
      end
    end
  end
  subject { described_class.new(image).generate_solr_document }

  context "with a file_set" do
    let(:image) { Image.new }
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
      allow(image).to receive_messages(file_sets: [file_set])
    end

    it "has images" do
      VCR.use_cassette("image_indexer") do
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
      end
    end
  end

  describe "Indexing dates" do
    context "with an issued date" do
      let(:image) { Image.new(issued_attributes: [{ start: ["1925-11"] }]) }

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1925-11"
      end
    end

    context "with an copyrighted date" do
      let(:copyrighted) { ["1913"] }
      let(:image) do
        Image.new(date_copyrighted_attributes: [{ start: copyrighted }])
      end

      it "indexes dates for display" do
        expect(subject["date_copyrighted_ssm"]).to eq copyrighted
      end
    end

    context "with issued.start and issued.finish" do
      let(:issued_start) { ["1917"] }
      let(:issued_end) { ["1923"] }
      let(:image) do
        Image.new(
          issued_attributes: [{ start: issued_start, finish: issued_end }]
        )
      end

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to eq "1917 - 1923"
      end
    end
  end

  context "with work type" do
    let(:image) { Image.new(work_type: [work_type]) }
    let(:work_type) do
      RDF::URI("http://id.loc.gov/vocabulary/resourceTypes/img")
    end

    it "indexes a label" do
      VCR.use_cassette("resource_type") do
        expect(subject["work_type_sim"]).to eq [work_type]
        expect(subject["work_type_label_sim"]).to eq ["Still Image"]
        expect(subject["work_type_label_tesim"]).to eq ["Still Image"]
      end
    end
  end

  context "with location" do
    let(:image) { Image.new(location: [location]) }
    let(:location) do
      RDF::URI("http://id.loc.gov/authorities/subjects/sh85072779")
    end

    it "indexes a label" do
      VCR.use_cassette("image_indexer") do
        expect(subject["location_sim"]).to eq [location]
        expect(subject["location_label_sim"]).to eq ["Kodiak Island (Alaska)"]
        expect(subject["location_label_tesim"]).to eq ["Kodiak Island (Alaska)"]
      end
    end
  end

  context "with a note" do
    subject do
      VCR.use_cassette("image_indexer") do
        Importer::Factory::ImageFactory.new(
          { title: ["This is Fine"],
            accession_number: ["bork"],
            notes_attributes: [
              { note_type: nil,
                value: "A dog holding a coffee cup in a burning house.", },
            ], },
          []
        ).run.to_solr
      end
    end

    it "indexes the note" do
      expect(subject["note_label_tesim"].count).to eq 1
      expect(subject["note_label_tesim"].first).to(
        eq "A dog holding a coffee cup in a burning house."
      )
    end
  end

  context "with a license" do
    let(:image) do
      Image.create(
        title: ["This is Fine"],
        license: [RDF::URI("http://rightsstatements.org/vocab/InC/1.0/")]
      )
    end

    it "indexes the license label" do
      VCR.use_cassette("image_indexer") do
        expect(subject["license_label_tesim"]).to eq ["In Copyright"]
      end
    end
  end

  context "with local and LOC rights holders" do
    let(:valerie) { Agent.create(foaf_name: "Valerie") }
    let(:valerie_uri) { RDF::URI(valerie.uri) }
    let(:image) { Image.new(rights_holder: [valerie_uri, regents_uri]) }
    let(:regents_uri) do
      RDF::URI("http://id.loc.gov/authorities/names/n85088322")
    end

    before do
      AdminPolicy.ensure_admin_policy_exists
    end

    it "indexes with a label" do
      VCR.use_cassette("image_indexer") do
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

  context "internal vs external iiif uris" do
    let(:image) { FactoryBot.create(:public_image) }
    let(:file) { File.new(fixture_file_path("images/cusbspcmss36_110108_1_a.tif")) }
    let(:file_set) { FactoryBot.create(:public_file_set) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
      image.members << file_set
      image.save
    end
    after do
      Rails.configuration.external_iiif_url = nil
    end
    context "iiif manifest" do
      it "uses internal riiif urls if there is no external riiif service defined" do
        Rails.configuration.external_iiif_url = nil
        image_indexer_solr_doc = described_class.new(image).generate_solr_document
        expect(image_indexer_solr_doc["file_set_iiif_manifest_ssm"].first).to match(%r{^/image-service/*})
      end
      it "uses external riiif urls if there is an external riiif service defined" do
        Rails.configuration.external_iiif_url = "http://localhost:8182/iiif/2/"
        image_indexer_solr_doc = described_class.new(image).generate_solr_document
        expect(image_indexer_solr_doc["file_set_iiif_manifest_ssm"].first).to match(/^#{Rails.configuration.external_iiif_url}*/)
      end
    end
    context "image urls" do
      it "uses internal riiif urls if there is no external riiif service defined" do
        Rails.configuration.external_iiif_url = nil
        image_indexer_solr_doc = described_class.new(image).generate_solr_document
        expect(image_indexer_solr_doc["image_url_ssm"].first).to match(%r{^/image-service/*})
        expect(image_indexer_solr_doc["large_image_url_ssm"].first).to match(%r{^/image-service/*})
        expect(image_indexer_solr_doc["thumbnail_url_ssm"].first).to match(%r{^/image-service/*})
        expect(image_indexer_solr_doc["square_thumbnail_url_ssm"].first).to match(%r{^/image-service/*})
      end
      it "uses external riiif urls if there is an external riiif service defined" do
        Rails.configuration.external_iiif_url = "http://localhost:8182/iiif/2/"
        image_indexer_solr_doc = described_class.new(image).generate_solr_document
        expect(image_indexer_solr_doc["image_url_ssm"].first).to match(/^#{Rails.configuration.external_iiif_url}*/)
        expect(image_indexer_solr_doc["large_image_url_ssm"].first).to match(/^#{Rails.configuration.external_iiif_url}*/)
        expect(image_indexer_solr_doc["thumbnail_url_ssm"].first).to match(/^#{Rails.configuration.external_iiif_url}*/)
        expect(image_indexer_solr_doc["square_thumbnail_url_ssm"].first).to match(/^#{Rails.configuration.external_iiif_url}*/)
      end
    end
  end
end
