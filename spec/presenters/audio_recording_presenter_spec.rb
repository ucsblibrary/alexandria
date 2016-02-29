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

  describe 'alternative' do
    subject { presenter.alternative }
    let(:attributes) { { 'alternative_tesim' => ['test alternative'] } }
    it { is_expected.to eq ['test alternative'] }
  end

  describe 'language' do
    subject { presenter.language }
    let(:attributes) { { 'language_label_ssm' => ['English'] } }
    it { is_expected.to eq ['English'] }
  end

  describe 'issue_number' do
    subject { presenter.issue_number }
    let(:attributes) { { 'issue_number_ssm' => ['Edison Gold Moulded Record: 8958'] } }
    it { is_expected.to eq ['Edison Gold Moulded Record: 8958'] }
  end

  describe 'matrix_number' do
    subject { presenter.matrix_number }
    let(:attributes) { { 'matrix_number_ssm' => ['123456'] } }
    it { is_expected.to eq ['123456'] }
  end

  describe 'issued' do
    subject { presenter.issued }
    let(:attributes) { { 'issued_ssm' => ['ca. 1903 - 1906'] } }
    it { is_expected.to eq ['ca. 1903 - 1906'] }
  end
end
