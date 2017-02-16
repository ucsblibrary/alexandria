# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::ScannedMapFactory do
  let(:files) { Dir["spec/fixtures/maps/*.tif"] }
  let(:collection_attrs) { { accession_number: ["SBHC Mss 36"], title: ["Test collection"] } }
  let(:a) do
    {
      accession_number: ["abc123def"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs,
      files: files,
      issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: "Title from item." }],
      title: ["Test map"],
    }
  end
  it "can make a ScannedMap" do
    VCR.use_cassette("map_factory1") do
      i = Importer::Factory::ScannedMapFactory.new(a, files).run
      expect(i).to be_instance_of(ScannedMap)
    end
  end
end
