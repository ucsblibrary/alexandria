# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::MapSetFactory do
  let(:collection_attrs) { { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] } }
  let(:attributes) do
    {
      accession_number: ["111213"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs,
      issued_attributes: [{ start: ["1936"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: "Title from item." }],
      title: ["Map Set of the Moon"],
    }
  end

  before do
    (Collection.all + MapSet.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
  end

  it "can make a MapSet" do
    expect(MapSet.count).to eq 0
    expect(Collection.count).to eq 0
    VCR.use_cassette("map_set_factory1") do
      i = Importer::Factory::MapSetFactory.new(attributes).run
      expect(i).to be_instance_of(MapSet)
    end
    expect(MapSet.count).to eq 1
    expect(Collection.count).to eq 1
  end
end
