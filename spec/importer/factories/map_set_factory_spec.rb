# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::Factory::MapSetFactory do
  before(:all) do
    (Collection.all + MapSet.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
    @collection_attrs = { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] }
    # A MapSet can contain many IndexMaps
    @index_map_id = %w(fk4057td1k fkx057td1x)
    @map_attrs =
      {
        accession_number: ["111213"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        index_map_id: @index_map_id,
        issued_attributes: [{ start: ["1925"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Map Set of the Moon"],
      }
    VCR.use_cassette("collection_factory") do
      @collection = Importer::Factory::CollectionFactory.new(@collection_attrs, []).run
    end
    VCR.use_cassette("map_set_factory1") do
      @map_set = Importer::Factory::MapSetFactory.new(@map_attrs).run
    end
  end
  context "making a MapSet" do
    it "can make a MapSet" do
      expect(@map_set).to be_instance_of(MapSet)
      expect(MapSet.count).to eq 1
      expect(Collection.count).to eq 1
    end
    it "attaches a MapSet to its Collection" do
      expect(@map_set.local_collection_id.first).to eql(@collection.id)
    end
    it "attaches a MapSet to its IndexMap" do
      expect(@map_set.index_map_id).to contain_exactly(*@index_map_id)
    end
  end
end
