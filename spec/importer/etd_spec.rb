# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::ETD do
  let(:importer) { described_class.new }

  let!(:collection) do
    create(:collection,
           id: "etds",
           title: ["ETDs"],
           accession_number: ["etds"],
           identifier: ["etds"])
  end

  before do
    # Don't print output messages during specs
    allow($stdout).to receive(:puts)
  end

  describe "#import" do
    context "with an existing ETD collection" do
      before { ETD.destroy_all }

      let(:meta) { ["#{fixture_path}/proquest/zipped/ETD_ucsb_0035D_13132_MARC.xml"] }
      let(:data) { ["#{fixture_path}/proquest/zipped/ETD_ucsb_0035D_13132.zip"] }
      let(:options) { { skip: 0 } }

      it "ingests the ETD and sets the permissions correctly" do
        expect(ETD.count).to eq 0

        VCR.use_cassette("etd_importer") do
          Importer::ETD.import(meta, data, options)
        end

        expect(ETD.count).to eq 1

        costa = ETD.first
        expect(costa.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID

        costa_set = costa.file_sets.first
        expect(costa_set.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID

        costa_set.admin_policy_id = AdminPolicy::RESTRICTED_POLICY_ID
        costa_set.save!
        expect(costa_set.admin_policy_id).to eq AdminPolicy::RESTRICTED_POLICY_ID

        VCR.use_cassette("etd_importer") do
          Importer::ETD.import(meta, data, options)
        end

        expect(ETD.count).to eq 1
        expect(ETD.first.file_sets.first.admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
      end
    end
  end

  describe "#collection" do
    context "when ETD collection already exists" do
      before { collection } # create existing collection

      it "finds existing collection" do
        expect(importer.collection).to eq collection
      end
    end

    context 'when ETD collection doesn\'t exist yet' do
      before { Collection.destroy_all }

      it "raises an exception" do
        expect do
          importer.run
        end.to change { ETD.count }.by(0)
          .and raise_error(CollectionNotFound, 'Not Found: Collection with accession number ["etds"]')
      end
    end
  end
end
