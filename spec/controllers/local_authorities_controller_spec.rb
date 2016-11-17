# frozen_string_literal: true

require "rails_helper"

describe LocalAuthoritiesController do
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }

  describe "#show" do
    let(:topic) { Topic.create!(label: ["A Local Subject"]) }
    it "shows public urls" do
      get :show, id: topic, format: :ttl
      expect(response.body).to include "<http://test.host/authorities/topics/#{topic.id}> <http://www.w3.org/2000/01/rdf-schema#label> \"A Local Subject\";"
    end
  end

  describe "#index" do
    describe "a regular user" do
      it "access is denied" do
        get :index
        expect(flash[:alert]).to match(/You are not authorized/)
        expect(response).to redirect_to root_url
      end
    end

    describe "logged in as admin user" do
      let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

      before do
        ActiveFedora::Cleaner.clean!
        AdminPolicy.ensure_admin_policy_exists
      end

      let!(:image) { create(:public_image) }
      let!(:person) { create(:person) }
      let!(:group) { create(:group) }
      let!(:org) { create(:org) }
      let!(:agent) { create(:agent) }
      let!(:topic) { Topic.create!(label: ["A Local Subject"]) }

      it "only shows the models for local authorities" do
        get :index
        doc_ids = assigns[:document_list].map(&:id)
        expect(doc_ids).to include(person.id)
        expect(doc_ids).to include(group.id)
        expect(doc_ids).to include(org.id)
        expect(doc_ids).to include(agent.id)
        expect(doc_ids).to_not include(image.id)
        expect(doc_ids).to include(topic.id)
      end
    end # logged in as admin
  end

  describe "#show_delete_link?" do
    let(:doc) { SolrDocument.new("has_model_ssim" => "Person") }
    subject { controller.send(:show_delete_link?, nil, document: doc) }

    context "for a metadata admin" do
      let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
      it { is_expected.to be true }
    end

    context "for a non-admin user" do
      it { is_expected.to be false }
    end
  end

  describe "#show_merge_link?" do
    let(:doc) { SolrDocument.new("has_model_ssim" => "Person") }
    subject { controller.send(:show_merge_link?, nil, document: doc) }

    context "for a non-admin user" do
      it { is_expected.to be false }
    end

    context "for a metadata admin" do
      let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }
      it { is_expected.to be true }
    end
  end
end
