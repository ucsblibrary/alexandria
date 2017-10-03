# frozen_string_literal: true

require "rails_helper"
require "importer"
require "active_fedora/cleaner"

describe Importer::Factory::IndexMapFactory do
  before(:all) do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists

    @files = Dir["#{fixture_path}/maps/*.tif"]
    @collection_attrs = {
      accession_number: ["MAP 01 02 03"],
      title: ["Maps of the Moon"],
    }
    @parent_id = "fk44q85873"
    # This is what IndexMapFactory gets handed from the CSV importer
    @map_attrs =
      {
        accession_number: ["456"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        parent_id: @parent_id,
        files: @files,
        issued_attributes: [
          {
            start: ["1925"],
            finish: [],
            label: [],
            start_qualifier: [],
            finish_qualifier: [],
          },
        ],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Index Map of the Moon"],
      }

    VCR.use_cassette("collection_factory") do
      @collection = Importer::Factory::CollectionFactory.new(
        @collection_attrs, []
      ).run
    end

    VCR.use_cassette("index_map_factory1") do
      @index_map = described_class.new(
        @map_attrs, @files
      ).run
    end
  end
  context "Making an IndexMap" do
    it "can make an IndexMap" do
      expect(@index_map).to be_instance_of(IndexMap)
      expect(IndexMap.count).to eq(1)
    end
    it "attaches an IndexMap to its Collection" do
      expect(@index_map.local_collection_id.first).to eql(@collection.id)
    end
    it "attaches an IndexMap to its MapSet" do
      expect(@index_map.parent_id).to eql(@parent_id)
    end
    it "creates only one FileSet even if you ingest the object again" do
      expect(@index_map.file_sets.size).to eq(1)

      VCR.use_cassette("index_map_factory1") do
        @index_map = described_class.new(
          @map_attrs, @files
        ).run
      end

      expect(@index_map.file_sets.size).to eq(1)
    end
    it "doesn't delete FileSets if you do a metadata-only re-import" do
      @index_map.reload.file_sets # Just in case file_sets is cached
      expect(@index_map.file_sets.size).to eq(1)

      object_id = @index_map.id
      fs_id = @index_map.file_sets.first.id

      @metadata_only_map_attrs = {
        accession_number: ["456"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
        collection: @collection_attrs,
        parent_id: @parent_id,
        issued_attributes: [
          {
            start: ["1926"],
            finish: [],
            label: [],
            start_qualifier: [],
            finish_qualifier: [],
          },
        ],
        notes_attributes: [{ value: "Title from item." }],
        title: ["Index Map of the Moon"],
      }

      VCR.use_cassette("index_map_factory3") do
        @index_map = described_class.new(
          @metadata_only_map_attrs, []
        ).run
      end

      expect(@index_map.file_sets.size).to eq(1)
      expect(@index_map.id).to eql(object_id) # same object id

      # same file_set id == file_set didn't change
      expect(@index_map.file_sets.first.id).to eql(fs_id)
    end
  end
end
