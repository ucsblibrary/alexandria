# frozen_string_literal: true

require "rails_helper"

RSpec.describe FullTextToSolrJob do
  let(:first_file) do
    Class.new do
      def self.content
        File.open(
          Rails.root.join("spec", "fixtures", "pdf", "sample_full.pdf")
        ).read
      end
    end
  end
  let(:second_file) do
    Class.new do
      def self.content
        File.open(
          Rails.root.join("spec", "fixtures", "pdf", "nexus_200106_artsupp.pdf")
        ).read
      end
    end
  end

  let(:files_from_fileset) do
    [first_file, second_file]
  end

  let(:image) { FactoryBot.create(:public_image) }
  let(:ftts) { described_class.new(image.id) }
  let(:solr) { RSolr.connect(url: ActiveFedora::SolrService.instance.conn.uri.to_s) }

  describe "#perform_now" do
    before do
      allow(ftts).to receive(:files).and_return(files_from_fileset)
      ftts.perform_now
    end

    it "adds the text to solr index from the first pdf" do
      response = solr.get "select", params:
                                      { q: "John Arnhold", qf: "all_text_timv" }
      num_found = response["response"]["numFound"]
      expect(num_found).to eq(1)
    end
    it "adds the text to the solr index from the second pdf" do
      response = solr.get "select", params:
                                      { q: "Kqyaanisqatsi", qf: "all_text_timv" }
      num_found = response["response"]["numFound"]
      expect(num_found).to eq(2)
    end
  end
end
