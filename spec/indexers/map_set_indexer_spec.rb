# frozen_string_literal: true

require "rails_helper"

describe MapSetIndexer do
  let(:map_set) do
    MapSet.create(
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      index_map_id: (1..11).map { |i| (100 + i).to_s },
      title: ["Lots O' Components"]
    )
  end

  # Having more than 10 component or index maps is significant
  # because by default a solr query will only return 10 records.
  # If you want the full set of records, you have to explictly
  # tell solr the number of rows to return.
  context "a map set with more than 10 component maps" do
    let(:cm_docs) do
      (1..11).map do |i|
        SolrDocument.new(id: i.to_s,
                         parent_id_ssim: map_set.id,
                         has_model_ssim: "ComponentMap")
      end
    end

    let(:im_docs) do
      (1..11).map do |i|
        SolrDocument.new(id: (100 + i).to_s,
                         accession_number_ssim: (100 + i).to_s,
                         parent_id_ssim: map_set.id,
                         has_model_ssim: "IndexMap")
      end
    end

    before do
      ActiveFedora::SolrService.add(cm_docs + im_docs)
      ActiveFedora::SolrService.commit
    end

    context "#generate_solr_document" do
      subject { described_class.new(map_set).generate_solr_document }

      it "returns the full list of component and index maps" do
        expect(subject["component_maps_ssim"]).to(
          contain_exactly(*cm_docs.map(&:id))
        )
        expect(subject["index_maps_ssim"]).to(
          contain_exactly(*im_docs.map { |im| im["accession_number_ssim"] })
        )
      end
    end
  end
end
