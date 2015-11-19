require 'rails_helper'

RSpec.describe WelcomeController, type: :controller do
  describe 'index' do
    before { get :index }

    it 'is successful' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end

    it 'uses the special welcome layout' do
      expect(response).to render_template(:welcome)
      expect(response).to_not render_template(:blacklight)
    end
  end

  describe 'about' do
    before { get :about }

    it 'is successful' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:about)
    end

    it 'uses the normal blacklight layout' do
      expect(response).to render_template(:blacklight)
      expect(response).to_not render_template(:welcome)
    end
  end
end
