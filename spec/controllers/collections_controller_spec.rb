require 'rails_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }

  describe '#index' do
    before do
      Collection.destroy_all
    end
    let!(:collection1) { create :public_collection }
    let!(:collection2) { create :public_collection }
    let!(:private_collection1) { create :collection }
    let!(:image) { create :image }

    context 'when not signed in' do
      it 'shows a list of public collections' do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to contain_exactly(collection1.id, collection2.id)
      end
    end

    context 'when the user is signed in' do
      let(:user) { create :user }
      before do
        sign_in user
      end

      it 'shows a list of collections accessible to me' do
        get :index
        expect(response).to be_successful
        expect(assigns[:document_list].map(&:id)).to contain_exactly(collection1.id, collection2.id)
      end
    end
  end

  describe '#show' do
    let(:collection) { create :public_collection, id: 'fk4v989d9j', members: [image, private_image], identifier: ['ark:/99999/fk4v989d9j'] }
    let(:private_image) { create :image }
    let(:image) { create :public_image }

    it 'shows nothing' do
      get :show, id: collection
      expect(response).to be_successful
      expect(assigns[:member_docs].map(&:id)).to eq [image.id]
    end
  end
end
