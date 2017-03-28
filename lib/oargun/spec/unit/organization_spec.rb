# frozen_string_literal: true

require "spec_helper"

describe Oargun::ControlledVocabularies::Organization do
  describe "validation" do
    subject { described_class.new(subject_term) }
    context "when the Organization is in the vocabulary" do
      let(:subject_term) { RDF::URI.new("http://id.loc.gov/vocabulary/organizations/mtjg") }
      it { is_expected.to be_valid }
    end

    context "when the Organization is not in the vocabulary" do
      let(:subject_term) { RDF::URI.new("http://foo.bar/authorities/names/n79081574") }
      it { is_expected.not_to be_valid }
    end
  end
end
