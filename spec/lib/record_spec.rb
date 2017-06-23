# frozen_string_literal: true

require "rails_helper"
require "record"

describe Record do
  describe "::references_for" do
    subject { described_class.references_for(record) }

    let!(:record) { ActiveFedora::Base.create }

    context "when record isnt referenced by any other record" do
      it "returns empty list" do
        expect(subject).to eq []
      end
    end

    context "when record is referenced by another record" do
      let!(:image) { create(:image, creator: [record.uri]) }

      before { record.reload }

      it "returns list of object IDs" do
        expect(subject).to eq [image.id]
      end
    end
  end
end
