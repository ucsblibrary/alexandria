# coding: utf-8
require 'rails_helper'

RSpec.describe 'welcome/index.html.erb', type: :view do
  it 'has a link to search for ETDs' do
    render
    expect(rendered).to have_link('Read more…', href: about_path)
  end
end
