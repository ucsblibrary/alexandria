# frozen_string_literal: true

require "rails_helper"

describe Merritt::ImportEtd do
  let(:ark) { "m5zw6jv4" }
  let(:ark_path) { "/d/ark%253A%252F13030%252F/4/producer%252F" }
  let(:sys_path) { "/d/ark%253A%252F13030%252Fm5zd31s2/2/producer%252/F" }
  let(:metadata_file) { "#{ark_path}Thornton_ucsb_0035D_14168_DATA.xml" }
  let(:dissertation_file) { "#{ark_path}Thornton_ucsb_0035D_14168.pdf" }
  let(:zip_file) { "#{sys_path}Barel_ucsb_0035D_67%252FSmall%2520Town.zip" }
  let(:wav_file) { "#{sys_path}Barel_ucsb_0035D_67%252FOri%2520Barel-DeathMoon.wav" }
  let(:supp_files) { [zip_file, wav_file] }
  let(:proquest_files) { [metadata_file, dissertation_file] + supp_files }
  let(:system_files) { ["#{ark_path}/4/system%252Fmrt-ingest.txt"] }
  let(:supp_urls) do
    supp_files.map { |s_file| Merritt::Feed::HOME + s_file }
  end
  let(:meta_url) { Merritt::Feed::HOME + metadata_file }
  let(:diss_url) { Merritt::Feed::HOME + dissertation_file }
  let(:pq_meta) { File.join(fixture_path, "merritt", "proquest_metadata.xml") }
  let(:pq_diss) { File.join(fixture_path, "merritt", "proquest_dissertation.pdf") }
  let(:etd) do
    Feedjira::Parser::AtomEntry.new(
      entry_id: "http://n2t.net/" + ark,
      links: proquest_files + system_files
    )
  end

  describe ".ark" do
    it "returns merritt ark" do
      expect(described_class.ark(etd)).to eq(ark)
    end
  end

  %w[proquest_files metadata_file dissertation_file supp_files].each do |meth|
    describe ".#{meth}" do
      it "returns the location for #{meth}" do
        expect(described_class.send(meth, etd)).to eq(send(meth))
      end
    end
  end

  describe ".metadata_url" do
    it "returns url for metadata file" do
      expect(described_class.metadata_url(etd))
        .to eq(meta_url)
    end
  end

  describe ".dissertation_url" do
    it "returns url for dissertation file" do
      expect(described_class.dissertation_url(etd))
        .to eq(Merritt::Feed::HOME + dissertation_file)
    end
  end

  describe ".supp_urls" do
    it "returns url for supplemental files" do
      expect(described_class.supp_urls(etd))
        .to eq(supp_urls)
    end
  end

  describe ".get_content" do
    before do
      VCR.turn_off!(ignore_cassettes: true)
    end

    after do
      VCR.turn_on!
    end

    describe "with a non 200 response" do
      before do
        body = 'You are being <a href="http://merritt.cdlib.org/guest_login">
        redirected</a>.'
        stub_request(:get, meta_url)
          .to_return(headers: {}, body: body, status: [302, "HTTPFound"])
        Net::HTTP::Get.new(meta_url)
      end

      it "raises an error" do
        expect { described_class.get_content(meta_url) }
          .to raise_error(Net::HTTPError)
      end
    end

    describe "with metadata file url" do
      before do
        stub_request(:get, meta_url)
          .to_return(headers: {}, body: File.read(pq_meta), status: [200, "OK"])
        Net::HTTP::Get.new(meta_url)
      end

      it "returns the metadata xml file" do
        expect(described_class.get_content(meta_url))
          .to eq(File.read(pq_meta))
      end
    end

    describe "with dissertation file url" do
      before do
        stub_request(:get, diss_url)
          .to_return(headers: {}, body: File.read(pq_diss), status: [200, "OK"])
        Net::HTTP::Get.new(diss_url)
      end

      it "returns the metadata xml file" do
        expect(described_class.get_content(diss_url))
          .to eq(File.read(pq_diss))
      end
    end
  end

  describe ".escape_encodings" do
    it "escapes html url encodings" do
      expect(described_class.escape_encodings(meta_url))
        .to eq("Thornton_ucsb_0035D_14168_DATA.xml")
    end
  end
end
