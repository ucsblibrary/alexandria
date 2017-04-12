# frozen_string_literal: true

require "rails_helper"

describe MultiValueReadonlyInput, type: :input do
  let(:image) { Image.new(record_origin: ["value 1", "value 2"]) }
  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) { MultiValueReadonlyInput.new(builder, :record_origin, nil, :multi_value, {}) }

  describe "#input" do
    subject do
      input.input({})
    end

    it "renders multi-value" do
      # 'field-wrapper' is the class that causes the editor to be displayed. We don't want that.
      expect(subject).not_to match(/field-wrapper/)
    end
  end

  describe "#collection" do
    subject { input.send(:collection) }

    it { is_expected.to contain_exactly("value 1", "value 2") }
  end
end
