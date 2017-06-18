# frozen_string_literal: true

require "rails_helper"

describe RelatorInput, type: :input do
  let(:image) { Image.new }

  let(:bar1) do
    double(
      "value 1",
      rdf_label: ["Item 1"],
      rdf_subject: "http://example.org/1",
      node?: false
    )
  end

  let(:bar2) do
    double(
      "value 2",
      rdf_label: ["Item 2"],
      rdf_subject: "http://example.org/2"
    )
  end

  let(:builder) { SimpleForm::FormBuilder.new(:image, image, view, {}) }
  let(:input) { RelatorInput.new(builder, :creator, nil, :multi_value, {}) }

  describe "#input" do
    before do
      allow(image).to receive(:[]).with(:creator).and_return([bar1, bar2])
    end

    it "renders multi-value" do
      expect(input).to receive(:build_field).with(bar1, 0)
      expect(input).to receive(:build_field).with(bar2, 1)
      input.input({})
    end
  end

  describe "#build_field" do
    subject { input.send(:build_field, value, 0) }

    context "for a b-node" do
      let(:value) do
        double(
          "value 1",
          rdf_label: [""],
          rdf_subject: "_:134",
          node?: true,
          predicate: :programmer
        )
      end

      it "renders multi-value" do
        expect(subject).to(
          have_field("image[creator_attributes][0][hidden_label]",
                     with: "")
        )
        expect(subject).to have_selector("input.image_creator.multi_value")
        expect(subject).to(
          have_selector('input[name="image[creator_attributes][0][_destroy]"]',
                        visible: false)
        )
        expect(subject).to(
          have_selector(
            'input[name="image[creator_attributes][0][id]"][value=""]',
            visible: false
          )
        )
      end
    end

    context "for a resource" do
      let(:value) do
        double(
          "value 1",
          rdf_label: ["Item 1"],
          rdf_subject: "http://example.org/1",
          node?: false,
          predicate: :programmer
        )
      end

      it "renders multi-value" do
        expect(subject).to(
          have_field("image[creator_attributes][0][hidden_label]",
                     with: "Item 1")
        )

        expect(subject).to have_selector("input.image_creator.multi_value")

        # rubocop:disable Metrics/LineLength
        expect(subject).to(
          have_selector(
            'input[name="image[creator_attributes][0][_destroy]"][value=""][data-destroy]',
            visible: false
          )
        )
        expect(subject).to(
          have_selector(
            'input[name="image[creator_attributes][0][id]"][value="http://example.org/1"]',
            visible: false
          )
        )
        # rubocop:enable Metrics/LineLength
      end
    end

    context "for an ActiveFedora object" do
      let(:person) { Person.new(id: "ffffff", foaf_name: "Item 1") }
      let(:value) { ImageForm::Contributor.new(person, :actor) }

      it "renders multi-value" do
        expect(subject).to(
          have_field("image[creator_attributes][0][hidden_label]",
                     with: "Item 1")
        )
        expect(subject).to have_selector(".role .predicate", text: "Actor")
        expect(subject).to have_selector("input.image_creator.multi_value")

        # rubocop:disable Metrics/LineLength
        expect(subject).to(
          have_selector(
            "input[name=\"image[creator_attributes][0][id]\"][value=\"#{ActiveFedora.fedora.host}/test/ff/ff/ff/ffffff\"]",
            visible: false
          )
        )

        expect(subject).to(
          have_selector(
            'input[name="image[creator_attributes][0][_destroy]"][value=""][data-destroy]',
            visible: false
          )
        )
        expect(subject).to(
          have_selector(
            'input[name="image[creator_attributes][0][predicate]"][value="actor"]',
            visible: false
          )
        )
        # rubocop:enable Metrics/LineLength
      end
    end
  end
end
