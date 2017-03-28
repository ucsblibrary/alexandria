# frozen_string_literal: true

require "rails_helper"

describe MapSetIndexer do
  let(:map_set) { create(:public_map_set) }

  # Having more than 10 component or index maps is significant
  # because by default a solr query will only return 10 records.
  # If you want the full set of records, you have to explictly
  # tell solr the number of rows to return.
  context "a map set with more than 10 component maps" do
    let(:cm_docs) do
      docs = []
      for i in 1..11 do
        docs << SolrDocument.new(id: i.to_s,
                                 parent_id_ssim: map_set.id,
                                 has_model_ssim: "ComponentMap")
      end
      docs
    end

    let(:im_docs) do
      docs = []
      for i in 1..11 do
        docs << SolrDocument.new(id: (100 + i).to_s,
                                 parent_id_ssim: map_set.id,
                                 has_model_ssim: "IndexMap")
      end
      docs
    end

    before do
      ActiveFedora::SolrService.add(cm_docs + im_docs)
      ActiveFedora::SolrService.commit
    end

    context "#generate_solr_document" do
      subject { described_class.new(map_set).generate_solr_document }

      it "returns the full list of component and index maps" do
        expect(subject["component_maps_ssim"]).to eq cm_docs.map(&:id)
        expect(subject["index_maps_ssim"]).to eq im_docs.map(&:id)
      end
    end
  end
end
