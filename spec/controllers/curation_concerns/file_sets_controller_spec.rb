require 'rails_helper'

describe CurationConcerns::FileSetsController do
  describe "#show" do
    let(:file_set) do
      FileSet.create!(title: ["old wax"], admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end

    let(:user) { create :user }
    before { sign_in user }

    it "is successful" do
      get :show, id: file_set
      expect(response).to be_successful
    end
  end
end

