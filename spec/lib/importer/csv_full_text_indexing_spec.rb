# frozen_string_literal: true

require "active_fedora/cleaner"
require "rails_helper"
require "importer"
require "parse"
require "httparty"

describe Importer::CSV do
  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists
  end

  let(:data) { Dir["#{fixture_path}/pdf/*"] }
  let(:logger) { Logger.new(STDOUT) }
  let(:connection_url) { ActiveFedora::SolrService.instance.conn.uri }

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
      end
      expect(Image.count).to eq(1)
      result = HTTParty.get(
        "#{connection_url}select?&q=exxon&qf=all_text_timv&wt=json"
      )
      expect(result.parsed_response["response"]["numFound"]).to eq(1)
    end
  end
end
