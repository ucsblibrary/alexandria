require 'rails_helper'

describe DownloadsController do
  describe '#asset' do
    before do
      allow(controller).to receive(:params).and_return(id: 'ca%2Fc0%2Ff3%2Ff4%2Fcac0f3f4-ea8f-414d-a7a5-3253ef003b1a')
    end
    it 'decodes the id' do
      expect(ActiveFedora::Base).to receive(:find).with('ca/c0/f3/f4/cac0f3f4-ea8f-414d-a7a5-3253ef003b1a')
      controller.send(:asset)
    end
  end

  describe '#show' do
    let(:file_path) { File.join(fixture_path, 'pdf', 'sample.pdf') }
    let(:policy_id) { AdminPolicy::RESTRICTED_POLICY_ID }
    let(:file_set) do
      FileSet.new(admin_policy_id: policy_id) do |fs|
        Hydra::Works::AddFileToFileSet.call(fs,
                                            File.new(file_path),
                                            :original_file)
      end
    end

    context 'a metadata admin user' do
      let(:user) { create(:metadata_admin) }
      before do
        sign_in user
      end

      context 'downloads a restricted object' do

        it 'is successful' do
          get :show, id: file_set
          expect(response).to be_successful
          # expect(response.headers['Content-Type']).to eq 'application/pdf'
          expect(response.headers['Content-Disposition']).to eq "inline; filename=\"sample.pdf\""
        end
      end

      context 'downloading a derivative of a restored copy (used for link to download an mp3)' do
        let(:file_set) do
          mock_model(FileSet, admin_policy_id: policy_id, restored: file)
        end
        let(:file) { double('restored file', original_name: 'real-name.wav') }
        before do
          allow(controller).to receive_messages(authorize_download!: true,
                                                asset: file_set,
                                                load_file: file_path)
        end

        it 'returns attachment as the disposition' do
          get :show, id: file_set, file: 'mp3', dl: true
          expect(response).to be_successful
          expect(response.headers['Content-Disposition']).to eq "attachment; filename=\"real-name.mp3\""
        end
      end
    end

    context 'not logged in' do
      before do
        get :show, id: file_set
      end

      context 'downloads a restricted object' do
        it 'denies access' do
          expect(response).to redirect_to new_user_session_path
          expect(flash[:alert]).to match(/You are not authorized/)
        end
      end
    end
  end # 'downloading a file'
end
