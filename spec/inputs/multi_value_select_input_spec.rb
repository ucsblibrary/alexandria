# frozen_string_literal: true

require "rails_helper"

describe MultiValueSelectInput, type: :input do
  subject { input.input(nil) }

  let(:image) { Image.new(digital_origin: values) }
  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) do
    described_class.new(
      builder,
      :digital_origin,
      nil,
      :multi_value_select,
      options
    )
  end

  let(:base_options) do
    { as: :multi_value_select, required: true, collection: %w[one two] }
  end

  let(:options) { base_options }

  context "when nothing is selected" do
    let(:values) { [""] }

    it "renders a blank option" do
      expect(subject).to have_selector 'select option[value=""]'
    end
  end

  context "when something is selected" do
    let(:values) { ["one"] }

    it "has no blanks" do
      expect(subject).to have_selector "select option:first-child", text: "one"
    end
  end
end
