require 'rails_helper'

describe CurationConcerns::AudioRecordingsController do
  describe "#show" do
    let(:recording) do
      AudioRecording.create!(title: ["old wax"], admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
    end

    let(:user) { create :user }
    before { sign_in user }

    it "is successful" do
      get :show, id: recording
      expect(response).to be_successful
    end
  end
end
