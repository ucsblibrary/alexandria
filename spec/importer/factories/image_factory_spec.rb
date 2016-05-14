require 'rails_helper'

describe Importer::Factory::ImageFactory do
  let(:files) { Dir['spec/fixtures/images/dirge*'] }
  let(:collection_attrs) { { accession_number: ['SBHC Mss 36'], title: ['Test collection'] } }
  let(:attributes) do
    {
      accession_number: ['123'],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs.slice(:accession_number),
      files: files,
      issued_attributes: [{ start: ['1925'], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: 'Title from item.' }],
      title: ['Test image'],
    }
  end

  let(:factory) { described_class.new(attributes, files) }

  before do
    Collection.destroy_all
    ActiveFedora::Base.find('fk4c252k0f').destroy(eradicate: true) if ActiveFedora::Base.exists?('fk4c252k0f')
  end

  context 'with files' do
    before do
      Importer::Factory::CollectionFactory.new(collection_attrs).run
    end

    context 'for a new image' do
      it 'creates file sets with admin policies' do
        obj = factory.run
        expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
      end
    end

    context 'for an existing image without files' do
      before do
        create(:image, id: 'fk4c252k0f', accession_number: ['123'])
      end
      it 'creates file sets with admin policies' do
        expect do
          obj = factory.run
          expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
        end.not_to change { Image.count }
      end
    end
  end

  context 'when a collection already exists' do
    let!(:coll) { Collection.create!(collection_attrs) }

    it 'does not create a new collection' do
      expect(coll.members.size).to eq 0
      expect_any_instance_of(Collection).to receive(:save!).once
      expect do
        factory.run
      end.to change { Collection.count }.by(0)
      expect(coll.reload.members.size).to eq 1
    end
  end
end
