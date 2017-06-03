# frozen_string_literal: true

require "rails_helper"

describe EmbargoesController do
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  let(:user) { user_with_groups [AdminPolicy::PUBLIC_GROUP] }
  let(:work) { create(:etd) }

  describe "#index" do
    context "when I am NOT a rights admin" do
      it "redirects" do
        get :index
        expect(response).to redirect_to root_url
      end
    end

    context "when I am a rights admin" do
      let(:user) { user_with_groups [AdminPolicy::RIGHTS_ADMIN] }

      it "shows me the page" do
        get :index
        expect(response).to be_success
      end
    end
  end

  describe "#destroy" do
    context "when I do not have edit permissions for the object" do
      it "denies access" do
        get :destroy, id: work
        expect(response).to redirect_to root_url
      end
    end

    context "when I have permission to edit the object" do
      let(:user) { user_with_groups [AdminPolicy::RIGHTS_ADMIN] }

      before do
        AdminPolicy.ensure_admin_policy_exists
        work.admin_policy_id = AdminPolicy::UCSB_CAMPUS_POLICY_ID
        work.visibility_during_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::UCSB_CAMPUS_POLICY_ID))
        work.visibility_after_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID))
        work.embargo_release_date = release_date.to_s
        work.save(validate: false)
        get :destroy, id: work
        work.reload
      end

      context "with an active embargo" do
        let(:release_date) { Time.zone.today + 2 }

        it "deactivates embargo without updating admin_policy_id and redirects" do
          expect(work.admin_policy_id).to eq AdminPolicy::UCSB_CAMPUS_POLICY_ID
          expect(response).to redirect_to solr_document_path(work)
        end
      end

      context "with an expired embargo" do
        let(:release_date) { Time.zone.today - 2 }

        it "deactivates embargo, updates the admin_policy_id and redirects" do
          expect(work.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          expect(response).to redirect_to solr_document_path(work)
        end
      end
    end
  end

  describe "#update" do
    context "when I have permission to edit the object" do
      let(:user) { user_with_groups [AdminPolicy::RIGHTS_ADMIN] }
      let(:release_date) { Time.zone.today + 2 }

      before do
        AdminPolicy.ensure_admin_policy_exists
        work.admin_policy_id = AdminPolicy::UCSB_CAMPUS_POLICY_ID
        work.visibility_during_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::UCSB_CAMPUS_POLICY_ID))
        work.visibility_after_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID))
        work.embargo_release_date = release_date.to_s
        work.embargo.save(validate: false)
        work.save(validate: false)
      end

      context "with an expired embargo" do
        let(:release_date) { Time.zone.today - 2 }
        it "deactivates embargo, update the visibility and redirect" do
          patch :update, batch_document_ids: [work.id]
          expect(work.reload.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          expect(response).to redirect_to embargoes_path
        end
      end
    end
  end
end
