require 'rails_helper'
require 'importer'

describe Importer::ETD do
  let(:importer) { described_class.new }

  let(:collection) do
    create(:collection,
           id: 'etds',
           title: ['ETDs'],
           accession_number: ['etds'],
           identifier: ['etds'])
  end

  before do
    # Don't print output messages during specs
    allow($stdout).to receive(:puts)
  end

  describe '#import' do
    context 'with an existing ETD collection' do
      before { collection }

      let(:meta) { ["#{Rails.root}/spec/fixtures/proquest/Batch\ 3/2013-11-06_Summer2013/etdadmin_upload_234724/Costa_ucsb_0035D_11752_MARC.xml"] }
      let(:data) { ["#{Rails.root}/spec/fixtures/proquest/Batch\ 3/2013-11-06_Summer2013/etdadmin_upload_234724/etdadmin_upload_234724.zip"] }
      let(:options) { { skip: 0 } }

      it 'ingests the ETD' do
        expect do
          VCR.use_cassette('etd_importer') do
            Importer::ETD.import(meta, data, options)
          end
        end.to change { ETD.count }.by 1
      end
    end
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
