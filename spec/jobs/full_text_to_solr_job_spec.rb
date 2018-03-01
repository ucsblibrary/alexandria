# frozen_string_literal: true

require "rails_helper"

RSpec.describe FullTextToSolrJob do
  let(:file) do
    File.open(Rails.root.join("spec", "fixtures", "pdf", "sample_full.pdf")).read
  end
  let(:image) { FactoryBot.create(:public_image) }
  let(:ftts) { described_class.new(image.id, file) }
  let(:solr) { RSolr.connect(url: ActiveFedora::SolrService.instance.conn.uri.to_s) }

  describe "#perform" do
    it "adds the text to solr index" do
      ftts.perform_now
      response = solr.get "select", params: { q: "John Arnhold", qf: "all_text_timv" }
      num_found = response["response"]["numFound"]
      expect(num_found).to eq(1)
    end
  end
end
