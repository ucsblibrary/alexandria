# frozen_string_literal: true

require "rails_helper"
require "importer"
require "active_fedora/cleaner"

describe Importer::Factory::AudioRecordingFactory do
  let(:data) { [File.join(fixture_path, "cylinders")] }
  let(:metadata) { "#{fixture_path}/cylinders/cylinders-objects.xml" }

  let(:attributes) do
    {
      id: "f3999999",
      title: ["Test Wax Cylinder"],
      files: ["Cylinder 4373", "Cylinder 4374", "Cylinder 4377"],
      issued_attributes: [{ start: [2014] }],
      system_number: ["123"],
      author: ["Valerie"],
      identifier: ["ark:/48907/f3999999"],
    }.with_indifferent_access
  end

  let(:factory) { described_class.new(attributes, data) }

  before do
    (Collection.all + AudioRecording.all).map(&:id).each do |id|
      if ActiveFedora::Base.exists?(id)
        ActiveFedora::Base.find(id).destroy(eradicate: true)
      end
    end

    # Don't fetch external records during specs
    allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external)

    # Don't run background jobs/derivatives during the specs
    allow(CharacterizeJob).to(
      receive_messages(perform_later: nil, perform_now: nil)
    )
  end

  describe "#cylinder_number" do
    subject { factory.cylinder_number(filegroup) }

    context "with a correct file name" do
      let(:filegroup) { Dir["#{fixture_path}/cylinders/cyl1-2/cusb-cyl0001*"] }

      it { is_expected.to eq "0001" }
    end

    context "with only the md5 for a correct file name" do
      let(:filegroup) do
        [File.join(fixture_path,
                   "cylinders",
                   "cyl1-2",
                   "cusb-cyl0001a.wav.md5"),]
      end

      it { is_expected.to be_nil }
    end

    context "with only a bad file name" do
      let(:filegroup) { ["some_bad_name"] }

      it { is_expected.to be_nil }
    end
  end

  describe "attaching files" do
    let(:audio) { AudioRecording.new(title: ["Audio 1"]) }

    let(:files) do
      [
        # include an empty filegroup
        [],
        # include non-WAV files
        Dir["#{fixture_path}/cylinders/cyl1-2/cusb-cyl0001*"],
        Dir["#{fixture_path}/cylinders/cyl1-2/cusb-cyl0002*"],
      ]
    end

    context "when there are already files attached" do
      before do
        allow(audio).to receive(:file_sets).and_return([double("a file")])
      end

      it "doesn't create any new filesets" do
        expect(FileSet).not_to receive(:create!)
        expect do
          factory.attach_files(audio, files)
        end.to change(FileSet, :count).by(0)
      end
    end

    context "when no files are attached yet" do
      it "attaches the files" do
        expect do
          factory.attach_files(audio, files)
        end.to change(FileSet, :count).by(2)

        expect(audio.file_sets.map(&:title)).to(
          contain_exactly(["Cylinder0001"], ["Cylinder0002"])
        )
        first_file = audio.file_sets.find { |fs| fs.title == ["Cylinder0001"] }
        expect(audio.representative).to eq first_file
      end
    end
  end # attaching files

  describe "#create_attributes" do
    subject { factory.create_attributes }

    it "adds the default attributes" do
      expect(subject[:admin_policy_id]).to eq AdminPolicy::PUBLIC_POLICY_ID

      expect(subject[:restrictions].first).to(
        start_with("MP3 files of the restored cylinders "\
                   "available for download are copyrighted "\
                   "by the Regents of the University of California")
      )
    end
  end

  context "with existing records" do
    it "attaches files and updates metadata" do
      expect(AudioRecording.count).to eq 0

      indexer = Traject::Indexer.new
      indexer.load_config_file("lib/traject/audio_config.rb")
      hash = indexer.map_record(MARC::XMLReader.new(metadata).first)
        .merge(issued_attributes: [{ start: [2222] }])

      VCR.use_cassette("audio_recording_factory") do
        indexer.writer.put hash
      end

      expect(AudioRecording.count).to eq 1
      audio = AudioRecording.first
      expect(audio.file_sets).to eq []
      expect(audio.issued.first.start).to eq [2222]

      indexer = Traject::Indexer.new
      indexer.load_config_file("lib/traject/audio_config.rb")
      indexer.settings(files_dirs: data)

      VCR.use_cassette("audio_recording_factory") do
        indexer.writer.put(
          indexer.map_record(MARC::XMLReader.new(metadata).first)
        )
      end

      expect(AudioRecording.count).to eq 1
      audio = AudioRecording.first
      expect(audio.file_sets).not_to eq []
      expect(audio.issued.first.start).to eq [1905]
    end
  end
end
