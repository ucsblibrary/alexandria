# frozen_string_literal: true

require "rails_helper"

describe "A controlled vocabulary" do
  subject { ControlledVocabularies::Geographic.new(location) }

  context "when the location is in LCSH" do
    let(:location) do
      RDF::URI.new("http://id.loc.gov/authorities/subjects/sh2010014379")
    end

    it { is_expected.to be_valid }
  end

  context "when the location is in LC names" do
    let(:location) do
      RDF::URI.new("http://id.loc.gov/authorities/names/n79081574")
    end

    it { is_expected.to be_valid }
  end

  context "when the location is not in the vocabulary" do
    let(:location) do
      RDF::URI.new("http://foo.bar/authorities/names/n79081574")
    end

    it { is_expected.not_to be_valid }
  end
end
