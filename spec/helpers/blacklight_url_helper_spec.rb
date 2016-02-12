require 'rails_helper'

describe BlacklightUrlHelper do
  describe '#url_for_document' do
    subject { helper.url_for_document(document) }

    let(:document) { SolrDocument.new(has_model_ssim: [model], id: 'fk4v989d9j', identifier_ssm: ['ark:/99999/fk4v989d9j']) }

    context 'with an image' do
      let(:model) { Image.to_class_uri }
      it { is_expected.to eq '/lib/ark:/99999/fk4v989d9j' }
    end

    context 'with an Etd' do
      let(:model) { ETD.to_class_uri }

      context 'that has an ark' do
        it { is_expected.to eq '/lib/ark:/99999/fk4v989d9j' }
      end

      context 'without an ark' do
        let(:search_state) { double('SearchState', url_for_document: document) }
        before { allow(helper).to receive(:search_state).and_return(search_state) }
        let(:document) { SolrDocument.new(has_model_ssim: [model], id: 'fk4v989d9j') }
        it { is_expected.to eq '/catalog/fk4v989d9j' }
      end
    end

    context 'with a collection' do
      let(:model) { Collection.to_class_uri }
      it { is_expected.to eq '/collections/fk4v989d9j' }
    end

    context 'a local authoritiy with a public URI' do
      let(:model) { Person.to_class_uri }
      let(:uri) { 'http://example.com/authorities/person/fk4v989d9j' }
      let(:document) { SolrDocument.new(has_model_ssim: [model], id: 'fk4v989d9j', identifier_ssm: ['ark:/99999/fk4v989d9j'], public_uri_ssim: [uri]) }
      it { is_expected.to eq uri }
    end
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe '#etd_url' do
    subject { helper.etd_url('123') }
    it { is_expected.to eq solr_document_url('123') }
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe '#image_url' do
    subject { helper.image_url('123') }
    it { is_expected.to eq solr_document_url('123') }
  end
end
