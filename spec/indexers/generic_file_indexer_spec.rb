require 'rails_helper'

describe GenericFileIndexer do
  let(:generic_file) { GenericFile.new(id: 'bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3') }
  before do
    generic_file.original.content = File.open(fixture_file_path('pdf/sample.pdf'))
    generic_file.original.original_name = 'sample.pdf'
  end

  let(:indexer) { described_class.new(generic_file) }

  describe '#generate_solr_document' do
    subject { indexer.generate_solr_document }

    it 'has the url, name and file size' do
      expect(subject['original_download_url_ss']).to eq 'http://test.host/downloads/bf%2F74%2F27%2F75%2Fbf742775-2a24-46dc-889e-cca03b27b5f3'
      expect(subject['original_filename_ss']).to eq 'sample.pdf'
      expect(subject['original_file_size_ss']).to eq 218_882
    end
  end
end
