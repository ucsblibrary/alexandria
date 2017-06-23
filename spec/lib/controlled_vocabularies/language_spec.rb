# frozen_string_literal: true

require "rails_helper"

describe ControlledVocabularies::Language do
  subject { described_class.new(subject_term) }

  context "when the language is in the vocabulary" do
    let(:subject_term) do
      RDF::URI.new("http://id.loc.gov/vocabulary/iso639-2/ara")
    end

    it { is_expected.to be_valid }
  end

  context "when the language is not in the vocabulary" do
    let(:subject_term) do
      RDF::URI.new("http://foo.bar/authorities/names/n79081574")
    end

    it { is_expected.not_to be_valid }
  end
end
