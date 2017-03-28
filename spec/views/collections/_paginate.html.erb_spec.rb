# frozen_string_literal: true

require "rails_helper"

describe "collections/_paginate.html.erb" do
  let(:sample_response) do
    { "responseHeader" => { "params" => { "rows" => 10 } },
      "response" => { "numFound" => 20, "start" => 0, "docs" => [] }, }
  end

  let(:response) { Blacklight::Solr::Response.new(sample_response, {}) }

  let(:id) { "fk4cv4pp5v" }
  let!(:collection) { create(:collection, id: id) }

  before do
    params[:id] = id
    assign(:response, response)
    render
  end

  it "draws the page" do
    expect(rendered).to have_link "2", href: "/collections/#{id}/page/2"
  end
end
