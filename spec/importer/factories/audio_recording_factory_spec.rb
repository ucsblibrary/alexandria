require 'rails_helper'
require 'importer'
require 'active_fedora/cleaner'

describe Importer::Factory::AudioRecordingFactory do
  let(:data) { Dir['spec/fixtures/cylinders/*.wav'] }
  let(:metadata) { 'spec/fixtures/cylinders/cylinders-objects.xml' }
  let(:collection) { 'spec/fixtures/cylinders/cylinders-collection.csv' }

  let(:collection_attrs) { { accession_number: ['Cylinders'], title: ['Wax cylinders'] } }
  let(:attributes) do
    {
      id: 'f3999999',
      title: ['Test Wax Cylinder'],
      collection: collection_attrs.slice(:accession_number),
      files: ['Cylinder 4373', 'Cylinder 4374', 'Cylinder 4377'],
      issued_attributes: [{ start: [2014] }],
      system_number: ['123'],
      author: ['Valerie'],
      identifier: ['ark:/48907/f3999999'],
    }.with_indifferent_access
  end

  let(:factory) { described_class.new(attributes, data) }

  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists

    # Don't run background jobs/derivatives during the specs
    allow(CharacterizeJob).to receive_messages(perform_later: nil, perform_now: nil)
  end

  context 'when a collection already exists' do
    it 'doesn\'t create a new collection' do
      expect(Collection.count).to eq 0
      head, tail = Importer::CSV.split(collection)
      attrs = Importer::CSV.csv_attributes(head, tail.first)

      VCR.use_cassette('audio_recording_factory', record: :new_episodes) do
        Importer::CSV.import(attributes: attrs, files: [])
      end
      expect(Collection.count).to eq 1

      MARC::XMLReader.new(metadata).each do |record|
        indexer = Traject::Indexer.new
        indexer.load_config_file('lib/traject/audio_config.rb')
        indexer.settings(cylinders: data)

        VCR.use_cassette('audio_recording_factory', record: :new_episodes) do
          indexer.writer.put indexer.map_record(record)
        end
      end

      expect(AudioRecording.count).to eq 10
      expect(Collection.count).to eq 1
    end
  end

  describe '#create_attributes' do
    subject { factory.create_attributes }

    it 'adds the default attributes' do
      expect(subject[:admin_policy_id]).to eq AdminPolicy::PUBLIC_POLICY_ID
      expect(subject[:restrictions].first).to match(/^MP3 files of the restored cylinders available for download are copyrighted by the Regents of the University of California/)
    end
  end

  context 'updating existing records' do
    before do
      ActiveFedora::Cleaner.clean!
      AdminPolicy.ensure_admin_policy_exists
    end

    it 'attaches files and updates metadata' do
      expect(AudioRecording.count).to eq 0

      indexer = Traject::Indexer.new
      indexer.load_config_file('lib/traject/audio_config.rb')
      indexer.settings(cylinders: [])
      hash = indexer.map_record(MARC::XMLReader.new(metadata).first)
                    .merge(issued_attributes: [{ start: [2222] }])

      VCR.use_cassette('audio_recording_factory', record: :new_episodes) do
        indexer.writer.put hash
      end

      expect(AudioRecording.count).to eq 1
      audio = AudioRecording.first
      expect(audio.file_sets).to eq []
      expect(audio.issued.flat_map(&:start)).to eq [2222]

      indexer = Traject::Indexer.new
      indexer.load_config_file('lib/traject/audio_config.rb')
      indexer.settings(cylinders: data)

      VCR.use_cassette('audio_recording_factory', record: :new_episodes) do
        indexer.writer.put indexer.map_record(MARC::XMLReader.new(metadata).first)
      end

      expect(AudioRecording.count).to eq 1
      audio = AudioRecording.first
      expect(audio.file_sets).to_not eq []
      expect(audio.issued.flat_map(&:start)).to eq [1912]
    end
  end
end
