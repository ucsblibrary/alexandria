require 'rails_helper'
require 'importer'

describe Importer::Factory::AudioRecordingFactory do
  let(:files_directory) { double("Files directory") }
  let(:factory) { described_class.new(attributes, files_directory) }
  let(:collection_attrs) { { accession_number: ['cylinders'], title: ['Wax cylinders'] } }

  let(:attributes) do
    {
      id: 'f3999999',
      title: ['Test Wax Cylinder'],
      collection: collection_attrs.slice(:accession_number),
      files: ["Cylinder 4373", "Cylinder 4374", "Cylinder 4377"],
      created_attributes: [{ start: [2014] }],
      system_number: ['123'],
      author: ['Valerie'],
      identifier: ['ark:/48907/f3999999']
    }.with_indifferent_access
  end

  before do
    AudioRecording.find('f3999999').destroy(eradicate: true) if AudioRecording.exists? 'f3999999'

    # The destroy ^up there^ is not removing the AudioRecord from the collection.
    Collection.destroy_all

    allow($stdout).to receive(:puts) # squelch output
    AdminPolicy.ensure_admin_policy_exists
    allow(AttachFilesToAudioRecording).to receive(:run) # skip importing files
  end

  context 'when a collection already exists' do
    let!(:coll) { Collection.create!(collection_attrs) }

    it 'doesn\'t create a new collection' do
      expect(coll.members.size).to eq 0
      obj = nil
      expect do
        obj = factory.run
      end.to change { Collection.count }.by(0)
      expect(coll.reload.members.size).to eq 1
      expect(coll.members.first).to be_instance_of AudioRecording
      expect(obj.id).to eq 'f3999999'
      expect(obj.system_number).to eq ['123']
      expect(obj.identifier).to eq ['ark:/48907/f3999999']
      expect(obj.author).to eq ['Valerie']
    end
  end

  describe '#create_attributes' do
    subject { factory.create_attributes }

    it "adds the default access policy to the Audio Recording's attributes" do
      expect(subject[:admin_policy_id]).to eq AdminPolicy::PUBLIC_POLICY_ID
    end
  end

  describe 'after_save' do
    let(:attributes) do
      { files: ['Cylinder 9999'] }
    end
    let(:audio) { AudioRecording.create }

    before { allow(factory).to receive(:add_object_to_collection) }

    context "if the audio doesn't have attached files" do
      it 'attaches files' do
        expect(AttachFilesToAudioRecording).to receive(:run).with(audio, files_directory, attributes[:files])
        factory.after_save(audio)
      end
    end
  end

  describe 'update an existing record' do
    let!(:coll) { Collection.create!(collection_attrs) }
    let(:old_date) { 2222 }
    let(:old_date_attrs) { { created_attributes: [{ start: [old_date] }] }.with_indifferent_access }

    context "when the created date hasn't changed" do
      let!(:audio) { create(:audio, attributes.except(:collection, :files)) }

      it "doesn't add a new duplicate date" do
        audio.reload
        expect(audio.created.flat_map(&:start)).to eq [2014]

        factory.update(audio)
        audio.reload
        expect(audio.created.flat_map(&:start)).to eq [2014]
      end
    end

    context 'when the created date has changed' do
      let!(:audio) { create(:audio, attributes.except(:collection, :files).merge(old_date_attrs)) }

      it 'updates the existing date instead of adding a new one' do
        audio.reload
        expect(audio.created.flat_map(&:start)).to eq [old_date]

        factory.update(audio)
        audio.reload
        expect(audio.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the AudioRecording doesn't have existing created date" do
      let!(:audio) { create(:audio, attributes.except(:collection, :files, :created_attributes)) }

      it 'adds the new date' do
        audio.reload
        expect(audio.created).to eq []

        factory.update(audio)
        audio.reload
        expect(audio.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the AudioRecording has existing created date, but new attributes don't have a date" do
      let(:attributes) do
        { id: 'f3999999',
          system_number: ['123'],
          identifier: ['ark:/48907/f3999999'],
          collection: collection_attrs.slice(:accession_number),
        }.with_indifferent_access
      end

      let!(:audio) { create(:audio, attributes.except(:collection).merge(old_date_attrs)) }

      it "doesn't change the existing date" do
        audio.reload
        expect(audio.created.first.start).to eq [old_date]

        factory.update(audio)
        audio.reload
        expect(audio.created.first.start).to eq [old_date]
      end
    end
  end # update an existing record
end

