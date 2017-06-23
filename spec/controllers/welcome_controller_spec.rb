# frozen_string_literal: true

require "rails_helper"

RSpec.describe WelcomeController, type: :controller do
  describe "index" do
    before { get :index }

    it "is successful" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:index)
    end
  end

  describe "about" do
    before { get :about }

    it "is successful" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:about)
    end

    it "uses the normal CC layout" do
      expect(response).to render_template(:curation_concerns)
      expect(response).not_to render_template(:welcome)
    end
  end
end
