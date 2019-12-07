# frozen_string_literal: true

require "rails_helper"

describe ControlledVocabularies::RightsStatement do
  subject { described_class.new(uri) }

  context "when the rights statement is in the vocabulary" do
    let(:uri) { RDF::URI.new("http://www.europeana.eu/rights/rr-f/") }

    it { is_expected.to be_valid }
  end

  context "when the rights statement is not in the vocabulary" do
    let(:uri) { RDF::URI.new("http://foo.bar/rights/rr-f/") }

    it { is_expected.not_to be_valid }
  end

  describe "#rdf_label" do
    context "with an opaquenamespace URI" do
      let(:uri) do
        RDF::URI.new("http://opaquenamespace.org/ns/rights/educational/")
      end

      it "finds the label" do
        expect(subject.rdf_label).to eq ["Educational Use Permitted"]
      end
    end

    context "with an invalid opaquenamespace URI" do
      let(:uri) do
        RDF::URI.new("http://opaquenamespace.org/rights/educational/")
      end

      it "raises an error" do
        expect { subject.rdf_label }.to raise_error TermNotFound
      end
    end
  end
end
