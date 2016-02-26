require 'rails_helper'

describe AttachFilesToAudioRecording do
  describe 'run' do
    let(:files_dir) { '/data/objects-cylinders' }
    let(:cylinder_names) { ["Cylinder 4373", "Cylinder 4374", "Cylinder 4377"] }
    let(:audio) { AudioRecording.create }

    let(:file1) { double("original 4373") }
    let(:file2) { double("restored 4373") }
    let(:file3) { double("original 4374") }
    let(:file4) { double("restored 4374") }
    let(:file5) { double("original 4377") }
    let(:file6) { double("restored 4377") }

    let(:actor) { double("the actor") }

    before do
      # squelch output
      allow($stdout).to receive(:puts)
      allow(CurationConcerns::FileSetActor).to receive(:new).with(FileSet, User.batchuser).and_return(actor)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4373a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4373/cusb-cyl4373a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4373/cusb-cyl4373a.wav')
                                  .and_return(file1)
      expect(actor).to receive(:create_content).with(file1)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4373b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4373/cusb-cyl4373b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4373/cusb-cyl4373b.wav')
                                  .and_return(file2)
      expect(actor).to receive(:create_content).with(file2, 'restored')

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4374a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4374/cusb-cyl4374a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4374/cusb-cyl4374a.wav')
                                  .and_return(file3)
      expect(actor).to receive(:create_content).with(file3)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4374b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4374/cusb-cyl4374b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4374/cusb-cyl4374b.wav')
                                  .and_return(file4)
      expect(actor).to receive(:create_content).with(file4, 'restored')

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4377a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4377/cusb-cyl4377a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4377/cusb-cyl4377a.wav')
                                  .and_return(file5)
      expect(actor).to receive(:create_content).with(file5)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4377b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4377/cusb-cyl4377b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4377/cusb-cyl4377b.wav')
                                  .and_return(file6)
      expect(actor).to receive(:create_content).with(file6, 'restored')

    end

    it 'attaches files' do
      described_class.run(audio, files_dir, cylinder_names)
      expect(audio.file_sets).to all(be_kind_of FileSet)
      expect(audio.file_sets.size).to eq 3
      expect(audio.file_sets.first.label).to eq "Cylinder 4373"
      expect(audio.file_sets.first.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
    end
  end
end

