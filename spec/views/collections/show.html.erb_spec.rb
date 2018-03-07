# frozen_string_literal: true

require "rails_helper"

describe "collections/show.html.erb", type: :view do
  helper ApplicationHelper,
         Blacklight::CatalogHelperBehavior,
         CurationConcerns::CollectionsHelper,
         SessionsHelper

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:member_docs) { [image1, image2] }
  let(:response) { Blacklight::Solr::Response.new(sample_response, {}) }

  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  let(:presenter) do
    CurationConcerns::CollectionPresenter.new(solr_document, nil)
  end

  let(:search_state) do
    instance_double("Blacklight::SearchState",
                    params_for_search: {},
                    url_for_document: solr_document)
  end

  let(:sample_response) do
    { "responseHeader" => { "params" => { "rows" => 3 } },
      "docs" => [], }
  end

  let(:image1) do
    SolrDocument.new(
      id: "234",
      identifier_ssm: ["ark:/99999/fk4v989d9j"],
      object_profile_ssm: ["{}"],
      has_model_ssim: ["Image"]
    )
  end

  let(:image2) do
    SolrDocument.new(
      id: "456",
      identifier_ssm: ["ark:/99999/fk4zp46p1g"],
      object_profile_ssm: ["{}"],
      has_model_ssim: ["Image"]
    )
  end

  let(:solr_document) do
    SolrDocument.new(
      id: "123",
      title_tesim: "My Collection",
      description: "Just a collection",
      has_model_ssim: ["Collection"]
    )
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to(
      receive(:blacklight_configuration_context)
        .and_return(blacklight_configuration_context)
    )
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:render_index_doc_actions).and_return nil
    allow(controller). to receive(:show_contributors?).and_return false
    allow(controller). to receive(:show_author?).and_return false
    allow(controller).to receive(:collection?).and_return(true)
    view.lookup_context.prefixes += ["catalog"]
    assign(:response, response)
    assign(:presenter, presenter)
    assign(:member_docs, member_docs)
    render
  end

  it "draws the page" do
    expect(rendered).to have_content "My Collection"
  end
end
