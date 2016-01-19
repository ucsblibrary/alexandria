require 'rails_helper'

RSpec.describe 'welcome/index.html.erb', type: :view do
  it 'has a link to search for ETDs' do
    render
    expect(rendered).to have_link 'electronic theses and dissertations', href: search_catalog_path('f[active_fedora_model_ssi][]' => 'ETD')
  end
end
