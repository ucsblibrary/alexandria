require 'rails_helper'

describe 'collections/show.html.erb' do
  let(:sample_response) do
    { 'responseHeader' => { 'params' => { 'rows' => 3 } },
      'docs' => [],
    }
  end
  let(:response) { Blacklight::Solr::Response.new(sample_response, {}) }
  let(:presenter) { CurationConcerns::CollectionPresenter.new(solr_document, nil) }
  let(:solr_document) { SolrDocument.new(id: '123', title_tesim: 'My Collection', description: 'Just a collection', has_model_ssim: ['Collection']) }

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:image1) { SolrDocument.new(id: '234', identifier_ssm: ['ark:/99999/fk4v989d9j'], 'object_profile_ssm' => ['{}'], 'has_model_ssim' => ['Image']) }
  let(:image2) { SolrDocument.new(id: '456', identifier_ssm: ['ark:/99999/fk4zp46p1g'], 'object_profile_ssm' => ['{}'], 'has_model_ssim' => ['Image']) }
  let(:member_docs) { [image1, image2] }
  let(:search_state) { double('SearchState', params_for_search: {}) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(view).to receive(:search_state).and_return(search_state)
    allow(view).to receive(:current_user).and_return(build(:user))
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:render_index_doc_actions).and_return nil
    # allow(controller).to receive(:show_type?).and_return(false)
    view.lookup_context.prefixes += ['catalog']
    assign(:response, response)
    assign(:presenter, presenter)
    assign(:member_docs, member_docs)
    render
  end

  it 'draws the page' do
    expect(rendered).to have_content 'My Collection'
  end
end
