# frozen_string_literal: true

require "rails_helper"

describe ControlledVocabularies::Subject do
  subject { described_class.new(subject_term) }

  context "when the subject is in the vocabulary" do
    let(:subject_term) do
      RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85062487")
    end

    it { is_expected.to be_valid }
  end

  context "when the subject is not in the vocabulary" do
    let(:subject_term) do
      RDF::URI.new("http://foo.bar/authorities/names/n79081574")
    end

    it { is_expected.not_to be_valid }
  end
end
