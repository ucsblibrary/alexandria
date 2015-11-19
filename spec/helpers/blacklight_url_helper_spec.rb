require 'rails_helper'

describe BlacklightUrlHelper do
  describe '#url_for_document' do
    let(:document) { SolrDocument.new(has_model_ssim: [model], id: 'fk/4v/98/fk4v989d9j', identifier_ssm: ['ark:/99999/fk4v989d9j']) }
    context 'with an image' do
      let(:model) { Image.to_class_uri }
      subject { helper.url_for_document(document) }
      it { is_expected.to eq '/lib/ark:/99999/fk4v989d9j' }
    end

    context 'with an Etd' do
      let(:model) { ETD.to_class_uri }
      subject { helper.url_for_document(document) }
      it { is_expected.to eq '/lib/ark:/99999/fk4v989d9j' }
    end

    context 'with a collection' do
      let(:model) { Collection.to_class_uri }
      subject { helper.url_for_document(document) }
      it { is_expected.to eq '/collections/fk4v989d9j' }
    end
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe '#etd_url' do
    subject { helper.etd_url('123') }
    it { is_expected.to eq catalog_url('123') }
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe '#image_url' do
    subject { helper.image_url('123') }
    it { is_expected.to eq catalog_url('123') }
  end
end
