# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::Factory::ImageFactory do
  let(:files) { [] }
  let(:collection_attrs) { { accession_number: ["SBHC Mss 36"], title: ["Test collection"] } }
  let(:attributes) do
    {
      accession_number: ["123"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs,
      files: files,
      issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: "Title from item." }],
      title: ["Test image"],
    }
  end

  let(:factory) { described_class.new(attributes, files) }

  before do
    (Collection.all + Image.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
  end

  context "with files" do
    let(:files) { Dir["#{fixture_path}/images/dirge*"] }

    before do
      VCR.use_cassette("image_factory") do
        Importer::Factory::CollectionFactory.new(collection_attrs).run
      end
    end

    context "for a new image" do
      it "creates file sets with admin policies" do
        obj = nil
        # New cassette to avoid ActiveFedora::IllegalOperation:
        #                         Attempting to recreate existing ldp_source
        VCR.use_cassette("image_factory-1") do
          obj = factory.run
        end
        expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
      end
    end

    context "for an existing image without files" do
      before do
        create(:image, id: "fk4c252k0f", accession_number: ["123"])
      end
      it "creates file sets with admin policies" do
        expect do
          obj = nil
          VCR.use_cassette("image_factory-2") do
            obj = factory.run
          end
          expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
        end.not_to(change { Image.count })
      end
    end
  end

  describe "collections:" do
    let(:ezid_ids) { attributes[:accession_number].first }

    # Don't try to mint ARKs during specs
    before { stub_out_ezid(ezid_ids) }

    context "when a collection already exists" do
      let!(:coll) { Collection.create!(collection_attrs) }

      it "adds the image to existing collection" do
        image = nil
        expect { image = factory.run }
          .to change { Collection.count }.by(0)

        expect(image.local_collection_id).to include(coll.id)

        # Make sure collection membership is indexed in solr
        solr = Blacklight.default_index.connection
        res = solr.select(params: { id: coll.id, qt: "document" })
        doc = res["response"]["docs"].first
        expect(doc["member_ids_ssim"]).to eq [image.id]
      end
    end

    context 'when collection doesn\'t exist yet' do
      let(:collection_id) { collection_attrs[:accession_number].first.delete(" ") }

      let(:ezid_ids) { [collection_id, attributes[:accession_number].first] }

      before do
        Collection.where(accession_number: collection_attrs[:accession_number]).each { |c| c.destroy(eradicate: true) }
      end

      it "creates collection and adds image to it" do
        image = nil
        expect { image = factory.run }
          .to change { Collection.count }.by(1)

        expect(image.local_collection_id).to include(collection_id)
      end
    end

    context "without collection attributes" do
      let(:factory) { described_class.new(attributes.except(:collection), files) }
      before { Collection.destroy_all }

      it 'doesn\'t add the image to any collection' do
        image = nil
        expect { image = factory.run }
          .to change { Collection.count }.by(0)

        expect(image.local_collection_id).to eq []
      end
    end
  end
end
