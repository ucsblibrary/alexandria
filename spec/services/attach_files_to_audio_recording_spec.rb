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

    before do
      # squelch output
      allow($stdout).to receive(:puts)
      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4373a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4373/cusb-cyl4373a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4373/cusb-cyl4373a.wav')
                                  .and_return(file1)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file1, :original_file)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4373b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4373/cusb-cyl4373b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4373/cusb-cyl4373b.wav')
                                  .and_return(file2)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file2, :restored)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4374a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4374/cusb-cyl4374a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4374/cusb-cyl4374a.wav')
                                  .and_return(file3)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file3, :original_file)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4374b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4374/cusb-cyl4374b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4374/cusb-cyl4374b.wav')
                                  .and_return(file4)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file4, :restored)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4377a.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4377/cusb-cyl4377a.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4377/cusb-cyl4377a.wav')
                                  .and_return(file5)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file5, :original_file)

      allow(Dir).to receive(:glob).with('/data/objects-cylinders/**/cusb-cyl4377b.wav')
                                  .and_return(['/data/objects-cylinders/4000s/4377/cusb-cyl4377b.wav'])
      allow(File).to receive(:new).with('/data/objects-cylinders/4000s/4377/cusb-cyl4377b.wav')
                                  .and_return(file6)
      expect(Hydra::Works::AddFileToFileSet).to receive(:call)
                                                  .with(FileSet, file6, :restored)

    end

    it 'attaches files' do
      described_class.run(audio, files_dir, cylinder_names)
      expect(audio.file_sets).to all(be_kind_of FileSet)
    end
  end
end

