require 'rails_helper'

describe AudioRecordingPresenter do
  let(:attributes) { {} }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe 'restrictions' do
    subject { presenter.restrictions }
    let(:attributes) { { 'restrictions_tesim' => ['test restrictions'] } }
    it { is_expected.to eq ['test restrictions'] }
  end
end
