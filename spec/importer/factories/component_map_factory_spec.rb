# frozen_string_literal: true
require "rails_helper"
require "importer"

describe Importer::Factory::ComponentMapFactory do
  let(:files) { Dir["spec/fixtures/maps/*.tif"] }
  let(:collection_attrs) { { accession_number: ["MAP 01 02 03"], title: ["Maps of the Moon"] } }
  let(:attributes) do
    {
      accession_number: ["789"],
      admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
      collection: collection_attrs,
      files: files,
      issued_attributes: [{ start: ["1936"], finish: [], label: [], start_qualifier: [], finish_qualifier: [] }],
      notes_attributes: [{ value: "Title from item." }],
      title: ["Component Map of the Moon"],
    }
  end

  before do
    (Collection.all + ComponentMap.all).map(&:id).each do |id|
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end
  end

  it "can make a ComponentMap" do
    VCR.use_cassette("component_map_factory1") do
      i = Importer::Factory::ComponentMapFactory.new(attributes, files).run
      expect(i).to be_instance_of(ComponentMap)
    end
  end
end
