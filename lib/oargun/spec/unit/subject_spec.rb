# frozen_string_literal: true

require "spec_helper"

describe Oargun::ControlledVocabularies::Subject do
  subject { described_class.new(subject_term) }

  context "when the subject is in the vocabulary" do
    let(:subject_term) { RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85062487") }
    it { is_expected.to be_valid }
  end

  context "when the subject is not in the vocabulary" do
    let(:subject_term) { RDF::URI.new("http://foo.bar/authorities/names/n79081574") }

    it { is_expected.not_to be_valid }
  end
end
