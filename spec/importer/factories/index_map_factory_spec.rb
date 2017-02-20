# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::IndexMapFactory do
  let(:files) { Dir["spec/fixtures/maps/*.tif"] }
  let(:collection_attrs) { { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] } }
  let(:attributes) do
    {
      accession_number: ["456"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs,
      files: files,
      issued_attributes: [{ start: ["1936"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: "Title from item." }],
      title: ["Index Map of the Moon"],
    }
  end

  before do
    (Collection.all + IndexMap.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
  end

  it "can make an IndexMap" do
    VCR.use_cassette("index_map_factory1") do
      i = Importer::Factory::IndexMapFactory.new(attributes, files).run
      expect(i).to be_instance_of(IndexMap)
    end
  end
end
