require 'rails_helper'

describe Collection do
  describe "#to_solr" do

    context 'with subject' do
      let(:label) { 'Motion picture industry' }
      let(:url) { 'http://id.loc.gov/authorities/subjects/sh85088047' }
      let(:lc_subject) { [RDF::URI.new(url)] }
      subject { Collection.new(lc_subject: lc_subject).to_solr }

      it 'has human-readable labels for subject' do
        expect(subject["lc_subject_tesim"]).to eq [url]
        expect(subject["lc_subject_sim"]).to eq [url]
        expect(subject["lc_subject_label_tesim"]).to eq [label]
        expect(subject["lc_subject_label_sim"]).to eq [label]
      end
    end

    context 'with form_of_work' do
      let(:label) { 'black-and-white negatives' }
      let(:url) { 'http://vocab.getty.edu/aat/300128343' }
      let(:type) { [RDF::URI.new(url)] }
      subject { Collection.new(form_of_work: type).to_solr }

      it 'has human-readable labels for form_of_work' do
        expect(subject["form_of_work_sim"]).to eq [url]
        expect(subject["form_of_work_tesim"]).to eq [url]
        expect(subject["form_of_work_label_sim"]).to eq [label]
        expect(subject["form_of_work_label_tesim"]).to eq [label]
      end
    end
  end
end
