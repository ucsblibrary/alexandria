require 'rails_helper'

describe LocalAuthority do
  describe '::local_authority_models' do
    subject { LocalAuthority.local_authority_models }

    it 'returns all the classes that are local authorities' do
      expect(subject).to eq [Agent, Person, Group, Organization, Topic]
    end
  end

  describe '::local_authority?' do
    subject { LocalAuthority.local_authority?(record) }

    context 'for a fedora object' do
      context 'that is a local authority' do
        let(:record) { Person.new }
        it { is_expected.to eq true }
      end

      context 'that isnt a local authority' do
        let(:record) { Image.new }
        it { is_expected.to eq false }
      end
    end

    context 'for a solr document' do
      context 'that is a local authority' do
        let(:record) { SolrDocument.new('has_model_ssim' => 'Topic') }
        it { is_expected.to eq true }
      end

      context 'that isnt a local authority' do
        let(:record) { SolrDocument.new('has_model_ssim' => 'Image') }
        it { is_expected.to eq false }
      end
    end
  end

  describe '::local_name_authority?' do
    subject { LocalAuthority.local_name_authority?(record) }

    context 'a record that is a local name' do
      let(:record) { SolrDocument.new('has_model_ssim' => 'Group') }
      it { is_expected.to eq true }
    end

    context 'a record that isnt a local name' do
      let(:record) { SolrDocument.new('has_model_ssim' => 'Topic') }
      it { is_expected.to eq false }
    end
  end

  describe '::local_subject_authority?' do
    subject { LocalAuthority.local_subject_authority?(record) }

    context 'a record that is a local subject' do
      let(:record) { SolrDocument.new('has_model_ssim' => 'Topic') }
      it { is_expected.to eq true }
    end

    context 'a record that isnt a local subject' do
      let(:record) { SolrDocument.new('has_model_ssim' => 'Agent') }
      it { is_expected.to eq false }
    end
  end
end
