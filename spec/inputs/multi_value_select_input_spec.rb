require 'rails_helper'

describe 'MultiValueSelectInput', type: :input do
  let(:image) { Image.new(digital_origin: values) }
  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) { MultiValueSelectInput.new(builder, :digital_origin, nil, :multi_value_select, options) }

  let(:base_options) { { as: :multi_value_select, required: true, collection: %w(one two) } }
  let(:options) { base_options }

  subject { input.input(nil) }
  context 'when nothing is selected' do
    let(:values) { [''] }
    it 'renders a blank option' do
      expect(subject).to have_selector 'select option[value=""]'
    end
  end

  context 'when something is selected' do
    let(:values) { ['one'] }
    it 'has no blanks' do
      expect(subject).to have_selector 'select option:first-child', text: 'one'
    end
  end
end
