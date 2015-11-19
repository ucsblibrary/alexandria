require 'rails_helper'

describe CatalogController do
  before do
    AdminPolicy.ensure_admin_policy_exists
  end

  describe 'the search results' do
    let!(:generic_file) { GenericFile.create! }
    let!(:image) { create(:public_image) }

    it 'only shows images (not GenericFiles)' do
      get :index
      found = assigns[:document_list].map(&:id)
      expect(found).to include(image.id)
      expect(found).to_not include(generic_file.id)
    end
  end

  describe 'show tools' do
    it 'includes the edit link' do
      expect(CatalogController.blacklight_config.show.document_actions.keys).to include :edit
    end

    it 'includes the access and embargo link' do
      expect(CatalogController.blacklight_config.show.document_actions.keys).to include :access
    end
  end

  describe 'show page' do
    context 'view a restricted file' do
      let(:restricted_image) { create(:image, :restricted) }

      before do
        sign_in user
        get :show, id: restricted_image
      end

      context 'logged in as an admin user' do
        let(:user) { create(:metadata_admin) }

        it 'is successful' do
          expect(response).to be_successful
          expect(response).to render_template(:show)
        end
      end

      context 'logged in as a UCSB user' do
        let(:user) { create(:ucsb_user) }

        it 'access is denied' do
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to match /You do not have sufficient access privileges/
        end
      end
    end
  end # show page
end
