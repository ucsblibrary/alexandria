# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::IndexMapFactory do
  before(:all) do
    (Collection.all + IndexMap.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
    @files = Dir["spec/fixtures/maps/*.tif"]
    @collection_attrs = { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] }
    @parent_id = "fk44q85873"
    # This is what IndexMapFactory gets handed from the CSV importer
    @map_attrs =
      {
        accession_number: ["456"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        parent_id: @parent_id,
        files: @files,
        issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Index Map of the Moon"],
      }
    VCR.use_cassette("collection_factory") do
      @collection = Importer::Factory::CollectionFactory.new(@collection_attrs, []).run
    end
    VCR.use_cassette("index_map_factory1") do
      @index_map = Importer::Factory::IndexMapFactory.new(@map_attrs, @files).run
    end
  end
  context "Making an IndexMap" do
    it "can make an IndexMap" do
      expect(@index_map).to be_instance_of(IndexMap)
      expect(IndexMap.count).to eql(1)
    end
    it "attaches an IndexMap to its Collection" do
      expect(@index_map.local_collection_id.first).to eql(@collection.id)
    end
    it "attaches an IndexMap to its MapSet" do
      expect(@index_map.parent_id).to eql(@parent_id)
    end
  end
end
