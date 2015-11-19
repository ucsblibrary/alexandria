require 'rails_helper'
require 'importer'

describe Importer::Factory::ETDFactory do
  let(:factory) { described_class.new(attributes, Settings.proquest_directory) }
  let(:collection_attrs) { { accession_number: ['etds'] } }

  let(:attributes) do
    {
      id: 'f3/gt/5k/61/f3gt5k61',
      collection: collection_attrs, files: [],
      created_attributes: [{ start: [2014] }],
      system_number: ['123'],
      author: ['Valerie'],
      identifier: ['ark:/48907/f3gt5k61']
    }.with_indifferent_access
  end

  before do
    if ETD.exists? 'f3/gt/5k/61/f3gt5k61'
      ETD.find('f3/gt/5k/61/f3gt5k61').destroy(eradicate: true)
    end

    allow($stdout).to receive(:puts) # squelch output
    AdminPolicy.ensure_admin_policy_exists
    allow(AttachFilesToETD).to receive(:run) # skip importing files
  end

  context 'when a collection already exists' do
    let!(:coll) { Collection.create(collection_attrs) }

    it 'should not create a new collection' do
      expect(coll.members.count).to eq 0
      obj = nil
      expect do
        obj = factory.run
      end.to change { Collection.count }.by(0)
      expect(coll.reload.members.count).to eq 1
      expect(coll.members.first).to be_instance_of ETD
      expect(obj.id).to eq 'f3/gt/5k/61/f3gt5k61'
      expect(obj.system_number).to eq ['123']
      expect(obj.identifier).to eq ['ark:/48907/f3gt5k61']
      expect(obj.author).to eq ['Valerie']
    end
  end

  describe '#create_attributes' do
    subject { factory.create_attributes }

    it "adds the default access policy to the ETD's attributes" do
      expect(subject[:admin_policy_id]).to eq AdminPolicy::RESTRICTED_POLICY_ID
    end
  end

  describe 'after_save' do
    let(:attributes) do
      { files: ['Plunkett_ucsb_0035D_11862.pdf'] }
    end
    let(:etd) { ETD.create }

    before { allow(factory).to receive(:add_object_to_collection) }

    context "if the etd doesn't have attached proquest data" do
      it 'attaches files' do
        expect(AttachFilesToETD).to receive(:run).with(etd, attributes[:files].first)
        factory.after_save(etd)
      end
    end
  end

  describe 'update an existing record' do
    let!(:coll) { Collection.create(collection_attrs) }
    let(:old_date) { 2222 }
    let(:old_date_attrs) { { created_attributes: [{ start: [old_date] }] }.with_indifferent_access }

    context "when the created date hasn't changed" do
      let!(:etd) { create(:etd, attributes.except(:collection, :files)) }

      it "doesn't add a new duplicate date" do
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]

        obj = factory.update(etd)
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context 'when the created date has changed' do
      let!(:etd) { create(:etd, attributes.except(:collection, :files).merge(old_date_attrs)) }

      it 'updates the existing date instead of adding a new one' do
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [old_date]

        expect { obj = factory.update(etd) }.not_to change { TimeSpan.count }
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the ETD doesn't have existing created date" do
      let!(:etd) { create(:etd, attributes.except(:collection, :files, :created_attributes)) }

      it 'adds the new date' do
        etd.reload
        expect(etd.created).to eq []

        obj = factory.update(etd)
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the ETD has existing created date, but new attributes don't have a date" do
      let(:attributes) do
        { id: 'f3/gt/5k/61/f3gt5k61',
          system_number: ['123'],
          identifier: ['ark:/48907/f3gt5k61'],
          collection: collection_attrs,
        }.with_indifferent_access
      end

      let!(:etd) { create(:etd, attributes.except(:collection).merge(old_date_attrs)) }

      it "doesn't change the existing date" do
        etd.reload
        expect(etd.created.first.start).to eq [old_date]

        obj = factory.update(etd)
        etd.reload
        expect(etd.created.first.start).to eq [old_date]
      end
    end
  end # update an existing record
end
