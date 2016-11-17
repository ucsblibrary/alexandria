# frozen_string_literal: true

require "rails_helper"
require "active_fedora/cleaner"
require "importer"

describe AuthService do
  before do
    ActiveFedora::Cleaner.clean!
    AdminPolicy.ensure_admin_policy_exists

    allow_any_instance_of(Riiif::ImagesController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Riiif::ImagesController).to receive(:params).and_return(params)
    allow_any_instance_of(Riiif::ImagesController).to receive(:on_campus?).and_return(true)

    data = Dir["#{fixture_path}/images/*"]
    meta = ["#{fixture_path}/csv/pamss045.csv"]
    VCR.use_cassette("csv_importer") do
      Importer::CSV.import(meta, data, skip: 0)
    end
  end

  describe "#can?" do
    let(:fs) { Image.first.file_sets.first }
    subject { AuthService.new(Riiif::ImagesController.new).can?(:show, fs) }

    context "public image" do
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

    context "private image" do
      let(:fs) { Image.first.file_sets.first }
      subject { AuthService.new(Riiif::ImagesController.new).can?(:show, fs) }

      before do
        fs.admin_policy_id = AdminPolicy::RESTRICTED_POLICY_ID
        fs.update_index
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
