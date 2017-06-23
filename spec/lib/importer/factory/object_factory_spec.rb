# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::Factory::ObjectFactory do
  before { AdminPolicy.ensure_admin_policy_exists }

  describe "#find" do
    context "existing object" do
      subject { importer.find }

      let(:importer) { Importer::Factory::ImageFactory.new(attributes, []) }
      let(:a_num) { ["acc num 1", "acc num 2"] }
      let(:image_attrs) do
        { title: ["Something Title"], accession_number: a_num }
      end
      let!(:image) { create(:image, image_attrs) }

      context "with an id" do
        let(:attributes) { { id: image.id } }

        it "finds the exisiting object" do
          expect(subject.class).to eq Image
          expect(subject.title).to eq image_attrs[:title]
        end
      end

      context "with accession_number" do
        let(:attributes) do
          { accession_number: [image.accession_number.first] }
        end

        it "finds the exisiting object" do
          expect(subject.class).to eq Image
          expect(subject.title).to eq image_attrs[:title]
        end
      end

      context "with neither id nor accession_number" do
        let(:attributes) { { accession_number: [] } }

        it "raises an error" do
          expect { subject }.to(
            raise_error(
              "Missing identifier: Unable to search for existing object "\
              "without either fedora ID or accession_number"
            )
          )
        end
      end
    end
  end

  describe "update existing image" do
    let(:importer) { Importer::Factory::ImageFactory.new(attributes, []) }
    let(:old_note) { { note_type: "old type", value: "old value" } }
    let(:image) { create(:image, notes_attributes: [old_note]) }

    context "with collection attributes" do
      let(:collection_attrs) do
        { accession_number: ["123"],
          title: ["Test Collection"],
          identifier: ["123"], }
      end
      let!(:coll) { create(:collection, collection_attrs) }
      let(:attributes) do
        { id: image.id,
          collection: collection_attrs, }
      end

      it "adds the image to the collection" do
        expect(image.local_collection_id).to eq []
        importer.run
        expect(image.reload.local_collection_id).to eq [coll.id]
      end
    end

    context "when there are no new notes (but old notes exist)" do
      let(:attributes) { { id: image.id, title: ["new title"] } }

      it "clears out the old notes" do
        expect(image.notes.count).to eq 1
        expect(image.notes[0].note_type).to eq ["old type"]
        expect(image.notes[0].value).to eq ["old value"]

        importer.run
        reloaded = image.reload

        expect(reloaded.notes.count).to eq 0
      end
    end

    context "with new notes" do
      let(:attributes) do
        { id: image.id,
          note:  ["an untyped note",
                  { type: "type 1", name: "note 1" },
                  { type: "type 2", name: "note 2" },], }
      end

      it "updates the notes" do
        expect(image.notes.count).to eq 1
        expect(image.notes[0].note_type).to eq ["old type"]
        expect(image.notes[0].value).to eq ["old value"]

        importer.run
        reloaded = image.reload
        expect(reloaded.notes.count).to eq 3

        expect(reloaded.notes.map(&:note_type)).to(
          contain_exactly([],
                          ["type 1"],
                          ["type 2"])
        )

        expect(reloaded.notes.map(&:value)).to(
          contain_exactly(["an untyped note"],
                          ["note 1"],
                          ["note 2"])
        )
      end
    end
  end

  describe "#transform_attributes" do
    subject { importer.send(:transform_attributes) }

    let(:importer) { Importer::Factory::ImageFactory.new(attributes, []) }

    context "with notes" do
      let(:attributes) do
        { note:  ["an untyped note",
                  { type: "type 1", name: "note 1" },
                  { type: "type 2", name: "note 2" },], }
      end

      it "parses the notes attributes" do
        expect(subject[:note]).to be_nil

        expect(subject[:notes_attributes][0]).to(
          eq(note_type: nil, value: "an untyped note")
        )
        expect(subject[:notes_attributes][1]).to(
          eq(note_type: "type 1", value: "note 1")
        )
        expect(subject[:notes_attributes][2]).to(
          eq(note_type: "type 2", value: "note 2")
        )
      end
    end
  end
end
