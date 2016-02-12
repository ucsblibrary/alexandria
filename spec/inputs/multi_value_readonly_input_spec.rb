require 'rails_helper'

describe 'MultiValueReadonlyInput', type: :input do
  let(:image) { Image.new(record_origin: ['value 1', 'value 2']) }
  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) { MultiValueReadonlyInput.new(builder, :record_origin, nil, :multi_value, {}) }

  describe '#input' do
    subject do
      expect(input).to receive(:build_field).with('value 1', 0)
      expect(input).to receive(:build_field).with('value 2', 1)
      input.input({})
    end
    it 'renders multi-value' do
      # 'field-wrapper' is the class that causes the editor to be displayed. We don't want that.
      expect(subject).not_to match(/field-wrapper/)
    end
  end

  describe '#collection' do
    subject { input.send(:collection) }

    it { is_expected.to eq ['value 1', 'value 2'] }
  end
end
