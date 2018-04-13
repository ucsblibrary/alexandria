# frozen_string_literal: true

require "active_fedora/cleaner"
require "rails_helper"
require "importer"

describe Importer::CSV do
  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists
  end

  let(:data) { Dir["#{fixture_path}/pdf/*"] }
  let(:logger) { Logger.new(STDOUT) }

  context "full-text indexing" do
    let(:metadata) { ["#{fixture_path}/csv/pdf.csv"] }

    it "creates a new pdf with full text indexed" do
      VCR.use_cassette("csv_importer") do
        described_class.import(
          meta: metadata,
          data: data,
          options: { skip: 0 },
          logger: logger
        )
        expect(Image.count).to eq(1)
        expect(Image.first.to_solr["all_text_timv"]).to include("Exxon")
      end
    end
  end
end
