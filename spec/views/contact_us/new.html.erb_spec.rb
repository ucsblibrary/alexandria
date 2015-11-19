require 'rails_helper'

RSpec.describe 'contact_us/new.html.erb', type: :view do
  before { render }

  it 'contains an invisible field for spam detection' do
    expect(rendered).to have_css('.invisible input#zipcode')
  end
end
