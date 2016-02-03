require 'rails_helper'

describe Person do
  describe '#rdf_label' do
    let(:person) { described_class.new(foaf_name: 'Justin') }
    subject { person.rdf_label }
    it { is_expected.to eq ['Justin'] }
  end

  describe '#to_partial_path' do
    subject { described_class.new.to_partial_path }
    it { is_expected.to eq 'catalog/document' }
  end

  describe '#to_solr' do
    before { AdminPolicy.ensure_admin_policy_exists }

    let(:person) { described_class.create(foaf_name: 'Justin') }
    subject { person.to_solr }

    it 'has the uri' do
      expect(subject['uri_ssim']).not_to be_blank
      expect(subject['public_uri_ssim']).to eq "http://#{Rails.application.config.host_name}/authorities/people/#{person.id}"
    end
  end

  describe '#public_uri' do
    let(:person) { described_class.new(foaf_name: 'Justin') }

    context "when the Person hasn't been saved yet" do
      it 'returns nil' do
        expect(person.public_uri).to be_nil
      end
    end
  end

end
