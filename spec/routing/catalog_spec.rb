require 'rails_helper'

describe 'routes to CatalogController:' do
  it 'has routes for arks' do
    expect(get: '/lib/ark:/99999/fk41234567')
      .to route_to(controller: 'catalog', action: 'show', id: 'ark:/99999/fk41234567')
  end
end
