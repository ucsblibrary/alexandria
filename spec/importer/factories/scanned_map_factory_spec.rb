# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::ScannedMapFactory do
  before(:all) do
    (Collection.all + ScannedMap.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
    @files = Dir["spec/fixtures/maps/*.tif"]
    @collection_attrs = { accession_number: ["SBHC Mss 36"], title: ["Test collection"] }
    @map_attrs =
      {
        accession_number: ["abc123def"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        files: @files,
        issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Test map"],
      }
    VCR.use_cassette("collection_factory") do
      @collection = Importer::Factory::CollectionFactory.new(@collection_attrs, []).run
    end
    VCR.use_cassette("map_factory1") do
      @scanned_map = Importer::Factory::ScannedMapFactory.new(@map_attrs, @files).run
    end
  end
  context "creating a ScannedMap" do
    it "can make a ScannedMap" do
      expect(@scanned_map).to be_instance_of(ScannedMap)
      expect(ScannedMap.count).to eql(1)
    end
    it "attaches a ScannedMap to its Collection" do
      expect(@scanned_map.local_collection_id.first).to eql(@collection.id)
    end
    it "has only one FileSet even if you ingest the object again" do
      expect(@scanned_map.file_sets.size).to eql(1)
      VCR.use_cassette("map_factory1") do
        @scanned_map = Importer::Factory::ScannedMapFactory.new(@map_attrs, @files).run
      end
      expect(@scanned_map.file_sets.size).to eql(1)
    end
    it "doesn't delete FileSets if you do a metadata-only re-import" do
      expect(@scanned_map.file_sets.size).to eql(1)
      VCR.use_cassette("map_factory1") do
        @scanned_map = Importer::Factory::ScannedMapFactory.new(@map_attrs, []).run
      end
      expect(@scanned_map.file_sets.size).to eql(1)
    end
  end
end
