require "rails_helper"

describe Merritt::Etd do
  let(:ark) { "ark:/13030/m5zw6jv4" }
  let(:metadata_file) { "/d/ark%253A%252F13030%252Fm5zw6jv4/4/producer%252FThornton_ucsb_0035D_14168_DATA.xml" }
  let(:dissertation_file) { "/d/ark%253A%252F13030%252Fm5zw6jv4/4/producer%252FThornton_ucsb_0035D_14168.pdf" }
  let(:supplemental_files) {
    %w[
      /d/ark%253A%252F13030%252Fm5zd31s2/2/producer%252FBarel_ucsb_0035D_67%252FSmall%2520Town.zip
      /d/ark%253A%252F13030%252Fm5zd31s2/2/producer%252FBarel_ucsb_0035D_67%252FOri%2520Barel-Death%2520of%2520a%2520Moon.wav
    ]
  }
  let(:proquest_files) { [metadata_file, dissertation_file] + supplemental_files }
  let(:system_files) {
    %w[
      /d/ark%253A%252F13030%252Fm5zw6jv4
      /d/ark%253A%252F13030%252Fm5zw6jv4/4/system%252Fmrt-ingest.txt
    ]
  }
  let(:supp_urls) { supplemental_files.map { |s_file| Merritt::Feed::HOME + s_file } }
  let(:etd_entry) {
    Feedjira::Parser::AtomEntry.new(
      entry_id: "http://n2t.net/" + ark,
      links: proquest_files + system_files
    )
  }

  describe ".merritt_id" do
    it "returns merritt ark" do
      expect(described_class.merritt_id(etd_entry)).to eq(ark)
    end
  end

  %w[proquest_files metadata_file dissertation_file supplemental_files].each do |meth|
    describe ".#{meth}" do
      it "returns the location for #{meth}" do
        expect(described_class.send(meth, etd_entry)).to eq(send(meth))
      end
    end
  end

  describe ".metadata_file_url" do
    it "returns url for metadata file" do
      expect(described_class.metadata_file_url(etd_entry)).to eq(Merritt::Feed::HOME + metadata_file)
    end
  end

  describe ".dissertation_file_url" do
    it "returns url for dissertation file" do
      expect(described_class.dissertation_file_url(etd_entry)).to eq(Merritt::Feed::HOME + dissertation_file)
    end
  end

  describe ".supplemental_file_urls" do
    it "returns url for supplemental files" do
      expect(described_class.supplemental_file_urls(etd_entry)).to eq(supp_urls)
    end
  end
end