require 'rails_helper'
require 'importer'

describe Importer::ETD do
  let(:importer) { described_class.new }

  let(:collection) do
    create(:collection, id: 'etds', title: ['ETDs'],
           accession_number: ['etds'], identifier: ['etds'])
  end

  before do
    # Don't print output messages during specs
    allow($stdout).to receive(:puts)
  end

  describe '#collection' do
    context 'when ETD collection already exists' do
      before { collection } # create existing collection

      it 'finds existing collection' do
        expect(importer.collection).to eq collection
      end
    end

    context 'when ETD collection doesn\'t exist yet' do
      before { Collection.destroy_all }

      it 'raises an exception' do
        expect {
          importer.run
        }.to change { ETD.count }.by(0)
          .and raise_error(CollectionNotFound, 'Not Found: Collection with accession number ["etds"]')
      end
    end
  end
end
