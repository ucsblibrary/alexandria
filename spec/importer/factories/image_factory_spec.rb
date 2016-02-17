require 'rails_helper'
require 'importer'

describe Importer::Factory::ImageFactory do
  let(:factory) { described_class.new(attributes) }
  let(:collection_attrs) { { accession_number: ['SBHC Mss 36'], title: ['Test collection'] } }

  let(:attributes) do
    {
      collection: collection_attrs.slice(:accession_number), files: [], accession_number: ['123'],
      title: ['Test image'],
      notes_attributes: [{ value: 'Title from item.' }],
      issued_attributes: [{ start: ['1925'], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }]
    }
  end

  # squelch output
  before { allow($stdout).to receive(:puts) }

  context 'when a collection already exists' do
    let!(:coll) { Collection.create!(collection_attrs) }

    it 'does not create a new collection' do
      expect(coll.members.size).to eq 0
      expect_any_instance_of(Collection).to receive(:save!).once
      expect do
        VCR.use_cassette('ezid') do
          factory.run
        end
      end.to change { Collection.count }.by(0)
      expect(coll.reload.members.size).to eq 1
    end
  end
end
