require 'rails_helper'

describe FileSetIndexer do
  before do
    FileSet.find('bf742775-2a24-46dc-889e-cca03b27b5f3').destroy(eradicate: true) if FileSet.exists?('bf742775-2a24-46dc-889e-cca03b27b5f3')
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
  end

  let(:file) { File.new(fixture_file_path('pdf/sample.pdf')) }
  let(:file_set) { FileSet.new(id: 'bf742775-2a24-46dc-889e-cca03b27b5f3') }
  let(:indexer) { described_class.new(file_set) }

  describe '#generate_solr_document' do
    subject { indexer.generate_solr_document }

    it 'has the url, name and file size' do
      expect(subject['original_download_url_ss']).to eq 'http://test.host/downloads/bf742775-2a24-46dc-889e-cca03b27b5f3'
      expect(subject['original_filename_ss']).to eq 'sample.pdf'
      expect(subject['original_file_size_ss']).to eq 218_882
      expect(subject['original_file_size_ss']).to eq 218_882
    end

    context "of an audio" do
      before do
        allow(file_set).to receive(:mime_type).and_return('audio/x-wave')
      end
      it "has a thumbnail" do
        expect(subject['thumbnail_url_ssm']).to match %r{^/assets/audio-.*\.png$}
      end
    end
  end
end
