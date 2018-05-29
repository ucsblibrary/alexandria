# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::ETD do
  let!(:collection) do
    create(:collection,
           id: "etds",
           title: ["ETDs"],
           accession_number: ["etds"],
           identifier: ["etds"])
  end

  describe "#import" do
    context "with an existing ETD collection" do
      before do
        ETD.destroy_all
        # Don't fetch external records
        allow_any_instance_of(RDF::DeepIndexingService).to(
          receive(:fetch_external)
        )
      end

      let(:meta) do
        ["#{fixture_path}/proquest/zipped/ETD_ucsb_0035D_13132_MARC.xml"]
      end

      let(:data) do
        ["#{fixture_path}/proquest/zipped/ETD_ucsb_0035D_13132.zip"]
      end

      let(:options) { { skip: 0 } }

      it "ingests the ETD and sets the permissions correctly" do
        expect(ETD.count).to eq 0

        VCR.use_cassette("etd_importer") do
          described_class.import(meta: meta, data: data, options: options)
        end

        # Since #import queues a background job
        collection.update_index

        expect(ETD.count).to eq 1

        costa = ETD.first
        expect(costa.file_sets.count).to eq 1

        expect(costa.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
        expect(costa.author.map(&:class)).to eq [ControlledVocabularies::Creator]
        expect(costa.issued).to eq ["2016"]
        expect(costa.keywords).to contain_exactly("Frick", "It.", "Dang")
        expect(costa.local_collection_id).to eq ["etds"]
        expect(costa.place_of_publication).to eq ["[Santa Barbara, Calif.]"]
        expect(costa.publisher).to(
          eq ["University of California, Santa Barbara"]
        )
        expect(costa.title).to eq ["I don't ingest right : what is my deal"]

        costa_set = costa.file_sets.first
        expect(costa_set.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID

        costa_set.admin_policy_id = AdminPolicy::RESTRICTED_POLICY_ID
        costa_set.save!
        expect(costa_set.admin_policy_id).to(
          eq AdminPolicy::RESTRICTED_POLICY_ID
        )

        VCR.use_cassette("etd_importer") do
          described_class.import(meta: meta,
                                 data: data,
                                 options: options)
        end

        expect(ETD.count).to eq 1
        expect(ETD.first.file_sets.first.admin_policy_id).to(
          eq AdminPolicy::DISCOVERY_POLICY_ID
        )
      end
    end
  end

  describe "#ensure_collection_exists" do
    context "when ETD collection already exists" do
      # create existing collection
      before { collection }

      it "finds existing collection" do
        expect(described_class.ensure_collection_exists).to eq collection
      end
    end

    context "when ETD collection doesn't exist yet" do
      before { Collection.destroy_all }

      it "raises an exception" do
        expect do
          described_class.ensure_collection_exists
        end.to(
          change(ETD, :count).by(0).and(
            raise_error(
              CollectionNotFound,
              "Not Found: Collection with accession number [\"etds\"]"
            )
          )
        )
      end
    end
  end
end
