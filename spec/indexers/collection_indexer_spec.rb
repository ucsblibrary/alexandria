require 'rails_helper'

describe CollectionIndexer do
  subject { described_class.new(collection).generate_solr_document }
  let(:collection) { Collection.new(attributes) }

  context 'collector with a URI' do
    let(:url) { 'http://id.loc.gov/authorities/names/n79064013' }
    let(:attributes) { { collector: [RDF::URI.new(url)] } }

    it 'has fields for collector' do
      VCR.use_cassette('jules_verne') do
        expect(subject['collector_tesim']).to eq [url]
        expect(subject['collector_label_tesim']).to eq ['Verne, Jules, 1828-1905']
      end
    end
  end

  context 'collector with a string' do
    let(:jules_verne) { 'Jules Verne' }
    let(:attributes) { { collector: [jules_verne] } }

    it 'has fields for collector' do
      expect(subject['collector_tesim']).to eq [jules_verne]
    end
  end

  context 'with subject' do
    let(:label) { 'Motion picture industry' }
    let(:url) { 'http://id.loc.gov/authorities/subjects/sh85088047' }
    let(:lc_subject) { [RDF::URI.new(url)] }
    let(:attributes) { { lc_subject: lc_subject } }

    it 'has human-readable labels for subject' do
      VCR.use_cassette('motion_picture_industry') do
        expect(subject['lc_subject_tesim']).to eq [url]
        expect(subject['lc_subject_sim']).to eq [url]
        expect(subject['lc_subject_label_tesim']).to eq [label]
        expect(subject['lc_subject_label_sim']).to eq [label]
      end
    end
  end

  context 'with form_of_work' do
    let(:label) { 'black-and-white negatives' }
    let(:url) { 'http://vocab.getty.edu/aat/300128343' }
    let(:type) { [RDF::URI.new(url)] }
    let(:attributes) { { form_of_work: type } }

    it 'has human-readable labels for form_of_work' do
      VCR.use_cassette('black_and_white_negatives') do
        expect(subject['form_of_work_sim']).to eq [url]
        expect(subject['form_of_work_tesim']).to eq [url]
        expect(subject['form_of_work_label_sim']).to eq [label]
        expect(subject['form_of_work_label_tesim']).to eq [label]
      end
    end
  end
end
