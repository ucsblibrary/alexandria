# frozen_string_literal: true

require "rails_helper"

describe CollectionsController do
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }

  describe "#index" do
    before do
      Collection.destroy_all
    end

    let!(:collection1) { create :public_collection }
    let!(:collection2) { create :public_collection }
    let!(:private_collection1) { create :collection }
    let!(:image) { create :image }

    context "when not signed in" do
      it "shows a list of public collections" do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to(
          contain_exactly(collection1.id, collection2.id)
        )
      end
    end

    context "when the user is signed in" do
      let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }

      it "shows a list of collections accessible to me" do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to(
          contain_exactly(collection1.id, collection2.id)
        )
      end
    end
  end

  describe "#show" do
    let(:collection) do
      create(
        :public_collection,
        id: "fk4v989d9j",
        members: [image, private_image],
        identifier: ["ark:/99999/fk4v989d9j"]
      )
    end

    let(:private_image) { create :image }
    let(:image) { create :public_image }

    it "shows only public image" do
      get :show, params: { id: collection }
      expect(response).to be_successful
      expect(assigns[:member_docs].map(&:id)).to eq [image.id]
    end
  end
end
