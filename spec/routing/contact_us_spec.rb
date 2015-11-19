require 'rails_helper'

RSpec.describe 'routes to contact_us controller:' do
  it 'has routes for "contact us"' do
    expect(get: contact_us_form_path)
      .to route_to(controller: 'contact_us', action: 'new')

    expect(post: contact_us_path)
      .to route_to(controller: 'contact_us', action: 'create')
  end
end
