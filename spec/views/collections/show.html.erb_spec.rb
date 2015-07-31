require 'rails_helper'

describe 'collections/show.html.erb' do
  let(:response) { Blacklight::SolrResponse.new(sample_response, {}) }
  let(:collection) { mock_model(Collection, id: '123', title: "My Collection", description: "Just a collection") }
  let(:metadata) {{ "extent_ssm" => ["702 digital objects"] }}

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:image1) { SolrDocument.new(id: '234', identifier_ssm: ['ark:/99999/fk4v989d9j'], 'object_profile_ssm' => ['{}'], 'has_model_ssim' => ['Image']) }
  let(:image2) { SolrDocument.new(id: '456', identifier_ssm: ['ark:/99999/fk4zp46p1g'], 'object_profile_ssm' => ['{}'], 'has_model_ssim' => ['Image']) }
  let(:member_docs) { [ image1, image2 ] }

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:render_index_doc_actions).and_return nil
    view.lookup_context.prefixes += ['catalog']
    assign(:response, response)
    assign(:collection, collection)
    assign(:member_docs, member_docs)
    assign(:document, SolrDocument.new(metadata))
    render
  end

  it "draws the page" do
    expect(rendered).to have_content "My Collection"
  end

  let(:sample_response) do
    {"responseHeader" => {"params" =>{"rows" => 3}},
     "docs" =>[]
    }
  end
end
