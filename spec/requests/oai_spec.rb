# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Oai requests", type: :request do
  let(:work) { create(:etd) }

  before do
    work.visibility = "open"
    work.save
  end

  it "renders the basic OAI response" do
    get "/catalog/oai?verb=Identify"
    expect(response).to be_success
    expect(response.body).to match(%r{https:\/\/alexandria.ucsb.edu\/catalog\/oai})
  end

  it "returns valid XML" do
    get "/catalog/oai"
    oai_xml = Nokogiri::XML(response.body)
    oai_xml.validate
    expect(oai_xml.errors).to eq([])
  end

  it "has dc as a metadata type" do
    get "/catalog/oai?verb=ListMetadataFormats"
    expect(response.body).to match(/oai_dc/)
  end

  it "has a record in the repo" do
    get "/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc"
    expect(response.body).to match(%r{<identifier>oai:ucsb:.*<\/identifier>})
  end

  it "has a record in the repo with a title" do
    get "/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc"
    expect(response.body).to match(%r{<dc:title>.*<\/dc:title>})
  end

  it "has a record in the repo with a dc identifier" do
    get "/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc"
    expect(response.body).to match(%r{<dc:identifier>.*<\/dc:identifier>})
  end
end
