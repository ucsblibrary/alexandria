require 'rails_helper'

describe 'routes for local authorities' do

  it 'has show routes for all types of local authorities' do
    LocalAuthority.local_authority_models.each do |model|
      expect(get: "/authorities/#{model.to_s.downcase.pluralize}/123-456").to route_to(controller: 'catalog', action: 'show', id: '123-456')
    end
  end

end
