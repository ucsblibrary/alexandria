require 'rails_helper'
require 'importer'

describe Importer::Factory::ImageFactory do
  let(:factory) { described_class.new(attributes) }
  let(:collection_attrs) { { accession_number: ['SBHC Mss 36'], title: ['Test collection'] } }

  let(:files) { [] }
  let(:attributes) do
    {
      collection: collection_attrs.slice(:accession_number), files: files, accession_number: ['123'],
      title: ['Test image'],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      notes_attributes: [{ value: 'Title from item.' }],
      issued_attributes: [{ start: ['1925'], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }]
    }
  end

  # squelch output
  before do
    allow($stdout).to receive(:puts)
    Collection.destroy_all
    ActiveFedora::Base.find('fk4c252k0f').destroy(eradicate: true) if ActiveFedora::Base.exists?('fk4c252k0f')
  end

  context 'with files' do
    let(:factory) { described_class.new(attributes, 'tmp/files') }
    let(:files) { ['img.png'] }
    let(:file) { double('the file') }
    let!(:coll) { Collection.create!(collection_attrs) }
    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:new).and_return(file)
    end
    context "for a new image" do
      it 'creates file sets with admin policies' do
        expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(FileSet, file, :original_file)
        VCR.use_cassette('ezid') do
          obj = factory.run
          expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
        end
      end
    end

    context "for an existing image without files" do
      before do
        create(:image, id: 'fk4c252k0f', accession_number: ['123'])
      end
      it 'creates file sets with admin policies' do
        expect {
          expect(Hydra::Works::AddFileToFileSet).to receive(:call).with(FileSet, file, :original_file)
          VCR.use_cassette('ezid') do
            obj = factory.run
            expect(obj.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          end
        }.not_to change { Image.count }
      end
    end
  end

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
