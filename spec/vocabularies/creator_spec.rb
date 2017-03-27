# frozen_string_literal: true

require "rails_helper"

describe "A controlled vocabulary" do
  before do
    ControlledVocabularies::Creator.use_vocabulary :lcnames, class: Vocabularies::LCNAMES
  end

  context "when the name is in the vocabulary" do
    let(:name) { RDF::URI.new("http://id.loc.gov/authorities/names/n79081574") }
    it "should create an object" do
      expect do
        ControlledVocabularies::Creator.new(name)
      end.not_to raise_error
    end
  end

  context "when the name is not in the vocabulary" do
    let(:name) { RDF::URI.new("http://foo.bar/authorities/names/n79081574") }
    let(:creator) { ControlledVocabularies::Creator.new(name) }
    it "should be a problem" do
      expect(creator).not_to be_valid
      expect(creator.errors[:base].first).to start_with "http://foo.bar/authorities/names/n79081574 is not a term in a controlled vocabulary"
    end
  end

  context "when initialized without an argument" do
    subject { ControlledVocabularies::Creator.new }
    it { is_expected.to be_a_node }
  end
end
