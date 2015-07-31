require 'rails_helper'

describe DownloadsController do

  describe '#asset' do
    before do
      allow(controller).to receive(:params).and_return(id: 'ca%2Fc0%2Ff3%2Ff4%2Fcac0f3f4-ea8f-414d-a7a5-3253ef003b1a')
    end
    it "decodes the id" do
      expect(ActiveFedora::Base).to receive(:find).with('ca/c0/f3/f4/cac0f3f4-ea8f-414d-a7a5-3253ef003b1a')
      controller.asset
    end
  end


  describe '#show' do
    let(:generic_file) {
      gf = GenericFile.new
      gf.original.original_name = 'sample.pdf'
      gf.original.content = File.new(File.join(fixture_path, 'pdf', 'sample.pdf'))
      gf.original.mime_type = 'application/pdf'
      gf
    }
    let(:etd) { ETD.new(generic_files: [generic_file],
                        admin_policy_id: policy_id) }

    before do
      AdminPolicy.ensure_admin_policy_exists
      etd.save!
    end

    context 'a metadata admin user' do
      let(:user) { create(:metadata_admin) }
      before do
        sign_in user
        get :show, id: generic_file
      end

      context 'downloads a restricted object' do
        let(:policy_id) { AdminPolicy::RESTRICTED_POLICY_ID }

        it 'is successful' do
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "application/pdf"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"sample.pdf\""
        end
      end
    end

    context 'not logged in' do
      before do
        get :show, id: generic_file
      end

      context 'downloads a restricted object' do
        let(:policy_id) { AdminPolicy::RESTRICTED_POLICY_ID }

        it 'denies access' do
          expect(response).to redirect_to new_user_session_path
          expect(flash[:alert]).to match /You are not authorized/
        end
      end
    end

  end  # 'downloading a file'

end
