require 'rails_helper'

describe AudioRecording do
  describe '#to_solr' do
    let(:audio) { described_class.new }
    it 'calls the ImageIndexer' do
      expect_any_instance_of(ObjectIndexer).to receive(:generate_solr_document).and_return({})
      audio.to_solr
    end

    describe 'human_readable_type' do
      subject { audio.to_solr[Solrizer.solr_name('human_readable_type', :facetable)] }
      it { is_expected.to eq 'Audio Recording' }
    end
  end
end
