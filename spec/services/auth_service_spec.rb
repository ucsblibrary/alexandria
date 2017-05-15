# frozen_string_literal: true

require "rails_helper"
require "active_fedora/cleaner"
require "importer"

describe AuthService do
  before do
    allow_any_instance_of(Riiif::ImagesController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Riiif::ImagesController).to receive(:params).and_return(params)
    allow_any_instance_of(Riiif::ImagesController).to receive(:on_campus?).and_return(true)
  end

  subject { AuthService.new(Riiif::ImagesController.new).can?(:show, fs) }

  describe "#can?" do
    context "public image" do
      let(:fs) do
        FileSet.create(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
      end

      context "thumbnail" do
        let(:params) { { "size" => "400" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }
          it { is_expected.to be true }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end

      context "image" do
        let(:params) { { "size" => "900" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }
          it { is_expected.to be true }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end
    end

    context "merely discoverable image" do
      let(:fs) do
        FileSet.create(admin_policy_id: AdminPolicy::DISCOVERY_POLICY_ID)
      end

      context "thumbnail" do
        let(:params) { { "size" => "400" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }
          it { is_expected.to be true }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end

      context "image" do
        let(:params) { { "size" => "900" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }
          it { is_expected.to be false }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end
    end

    context "private image" do
      let(:fs) do
        FileSet.create(admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID)
      end

      context "thumbnail" do
        let(:params) { { "size" => "400" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }
          it { is_expected.to be true }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end

      context "image" do
        let(:params) { { "size" => "900" } }

        context "accessed by ucsb user" do
          let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }
          it { is_expected.to be false }
        end

        context "accessed by admin" do
          let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
          it { is_expected.to be true }
        end
      end
    end
  end
end
