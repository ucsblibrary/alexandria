# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::Factory::ComponentMapFactory do
  before(:all) do
    (Collection.all + ComponentMap.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
    @files = Dir["#{fixture_path}/maps/*.tif"]
    @parent_id = "fk44q85873"
    @index_map_id = ["fk4057td1k"]
    @collection_attrs = { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] }
    @map_attrs =
      {
        accession_number: ["456"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        parent_id: @parent_id,
        index_map_id: @index_map_id,
        files: @files,
        issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Component Map of the Moon"],
      }
    VCR.use_cassette("collection_factory") do
      @collection = Importer::Factory::CollectionFactory.new(@collection_attrs, []).run
    end
    VCR.use_cassette("component_map_factory") do
      @component_map = Importer::Factory::ComponentMapFactory.new(@map_attrs, @files).run
    end
  end
  context "make a ComponentMap" do
    it "can make a ComponentMap" do
      expect(@component_map).to be_instance_of(ComponentMap)
      expect(ComponentMap.count).to eql(1)
    end
    it "attaches a ComponentMap to its Collection" do
      expect(@component_map.local_collection_id.first).to eql(@collection.id)
    end
    it "attaches a ComponentMap to its MapSet" do
      expect(@component_map.parent_id).to eql(@parent_id)
    end
    it "attaches a ComponentMap to its IndexMap" do
      expect(@component_map.index_map_id).to eql(@index_map_id)
    end
    it "has only one FileSet even if you ingest the object again" do
      expect(@component_map.file_sets.size).to eql(1)
      VCR.use_cassette("component_map_factory") do
        @component_map = Importer::Factory::ComponentMapFactory.new(@map_attrs, @files).run
      end
      expect(@component_map.file_sets.size).to eql(1)
    end
    it "doesn't delete FileSets if you do a metadata-only re-import" do
      expect(@component_map.file_sets.size).to eql(1)
      VCR.use_cassette("component_map_factory") do
        @component_map = Importer::Factory::ComponentMapFactory.new(@map_attrs, []).run
      end
      expect(@component_map.file_sets.size).to eql(1)
    end
  end
end
