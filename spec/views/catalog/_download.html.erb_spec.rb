require 'rails_helper'

describe 'catalog/_download.html.erb' do
  let(:document) { SolrDocument.new(id: '123') }
  let(:blacklight_config) { CatalogController.blacklight_config }

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    render 'catalog/download', document: document
  end

  it 'links to download the metadata' do
    expect(rendered).to have_link 'Download Metadata', href: '/catalog/123.ttl'
  end
end
