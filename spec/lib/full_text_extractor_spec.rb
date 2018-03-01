# frozen_string_literal: true

require "rails_helper"

RSpec.describe FullTextExtractor do
  let(:file) do
    File.open(Rails.root.join("spec", "fixtures", "pdf", "sample_full.pdf")).read
  end
  let(:fte) { described_class.new(file) }

  describe "getting some json that contains the text of a pdf" do
    it "returns some json" do
      expect(fte.text).to match(/John Arnhold/)
    end
  end
end
