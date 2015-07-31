require 'rails_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }

  describe "#index" do
    let(:user) { create :user }
    before do
      Collection.destroy_all
      sign_in user
    end

    context "with public collections" do
      let!(:collection1) { create :public_collection }
      let!(:collection2) { create :public_collection }
      let!(:image) { create :image }

      it "shows a list of collections" do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to eq [collection1.id, collection2.id]
        expect(assigns[:document_list].map(&:id)).not_to include [image.id]
      end
    end

    context "with a private collection" do
      let!(:collection1) { create :collection }

      it "shows nothing" do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to eq []
      end
    end
  end

  describe "#show" do
    let(:collection) { create :public_collection, id: 'fk/4v/98/9d/fk4v989d9j', members: [image], identifier: ['ark:/99999/fk4v989d9j'] }
    context "with private images" do
      let!(:image) { create :image }

      it "shows nothing" do
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:member_docs].map(&:id)).to eq []
      end
    end

    context "with public images" do
      let!(:image) { create :public_image }

      it "shows the image" do
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:member_docs].map(&:id)).to eq [image.id]
      end
    end
  end
end
