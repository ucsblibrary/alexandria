require 'rails_helper'

describe 'collections/_paginate.html.erb' do
  let(:sample_response) do
    { 'responseHeader' => { 'params' => { 'rows' => 10 } },
      'response' => { 'numFound' => 20, 'start' => 0, 'docs' => [] },
    }
  end

  let(:response) { Blacklight::Solr::Response.new(sample_response, {}) }

  before do
    # Rspec doesn't have a way to deal with engine routes in view specs
    # https://github.com/rspec/rspec-rails/issues/1250
    allow(view).to receive(:url_for).with('/collections?id=fk4cv4pp5v'
                                         ).and_return('/collections/fk4cv4pp5v')
    allow(view).to receive(:url_for).with('/collections?id=fk4cv4pp5v&page=2'
                                         ).and_return('/collections/fk4cv4pp5v?page=2')
    params[:id] = 'fk4cv4pp5v'
    assign(:response, response)
    render
  end

  it 'draws the page' do
    expect(rendered).to have_link '2', href: '/collections/fk4cv4pp5v?page=2'
  end
end
