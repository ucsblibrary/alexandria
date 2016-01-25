require 'rails_helper'

describe FileSetIndexer do
  let(:file_set) { FileSet.new(id: 'bf742775-2a24-46dc-889e-cca03b27b5f3') }
  before do
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        File.new(fixture_file_path('pdf/sample.pdf')),
                                        :original_file)
  end

  let(:indexer) { described_class.new(file_set) }

  describe '#generate_solr_document' do
    subject { indexer.generate_solr_document }

    it 'has the url, name and file size' do
      expect(subject['original_download_url_ss']).to eq 'http://test.host/downloads/bf742775-2a24-46dc-889e-cca03b27b5f3'
      expect(subject['original_filename_ss']).to eq 'sample.pdf'
      expect(subject['original_file_size_ss']).to eq 218_882
    end
  end
end
