require 'rails_helper'

describe 'ControlledVocabularyInput', type: :input do
  let(:image) { Image.new }
  let(:bar1) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', node?: false) }
  let(:bar2) { double('value 2', rdf_label: ['Item 2'], rdf_subject: 'http://example.org/2') }
  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) { ControlledVocabularyInput.new(builder, :creator, nil, :multi_value, {}) }

  describe '#input' do
    before { allow(image).to receive(:[]).with(:creator).and_return([bar1, bar2]) }
    it 'renders multi-value' do
      expect(input).to receive(:build_field).with(bar1, 0)
      expect(input).to receive(:build_field).with(bar2, 1)
      input.input({})
    end
  end

  describe '#build_field' do
    subject { input.send(:build_field, value, 0) }

    context 'for a b-node' do
      let(:value) { double('value 1', rdf_label: [], rdf_subject: '_:134', node?: true) }
      it 'renders multi-value' do
        expect(subject).to have_selector('input.image_creator.multi_value')
        expect(subject).to have_selector('input[name="image[creator_attributes][0][id]"][value=""]')
        expect(subject).to have_selector('input[name="image[creator_attributes][0][_destroy]"]')
        expect(subject).to have_field('image[creator_attributes][0][hidden_label]', with: '')
      end
    end

    context 'for a resource' do
      let(:value) { double('value 1', rdf_label: ['Item 1'], rdf_subject: 'http://example.org/1', node?: false) }
      it 'renders multi-value' do
        expect(subject).to have_selector('input.image_creator.multi_value')
        expect(subject).to have_field('image[creator_attributes][0][hidden_label]', with: 'Item 1')
        expect(subject).to have_selector('input[name="image[creator_attributes][0][id]"][value="http://example.org/1"]')
        expect(subject).to have_selector('input[name="image[creator_attributes][0][_destroy]"][value=""][data-destroy]')
      end
    end

    context 'for an ActiveFedora object' do
      let(:value) { Person.new(id: 'ff/ff/ff/ffffff', foaf_name: 'Item 1') }
      it 'renders multi-value' do
        expect(subject).to have_selector('input.image_creator.multi_value')
        expect(subject).to have_field('image[creator_attributes][0][hidden_label]', with: 'Item 1')
        expect(subject).to have_selector("input[name=\"image[creator_attributes][0][id]\"][value=\"#{ActiveFedora.fedora.host}/test/ff/ff/ff/ffffff\"]")
        expect(subject).to have_selector('input[name="image[creator_attributes][0][_destroy]"][value=""][data-destroy]')
      end
    end
  end
end
