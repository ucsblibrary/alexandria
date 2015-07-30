require 'rails_helper'

describe EmbargoesController do
  let(:user) { create(:rights_admin) }
  let(:work) { create(:etd) }

  before { sign_in user }

  describe "#index" do
    context "when I am NOT a rights admin" do
      let(:user) { create(:user) }
      it "redirects" do
        get :index
        expect(response).to redirect_to root_path
      end
    end

    context "when I am a rights admin" do
      it "shows me the page" do
        get :index
        expect(response).to be_success
      end
    end
  end

  describe "#destroy" do
    context "when I do not have edit permissions for the object" do
      let(:user) { create(:user) }
      it "denies access" do
        get :destroy, id: work
        expect(response).to redirect_to root_path
      end
    end

    context "when I have permission to edit the object" do
      before do
        AdminPolicy.ensure_admin_policy_exists
        expect(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        work.admin_policy_id = AdminPolicy::UCSB_CAMPUS_POLICY_ID
        work.visibility_during_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::UCSB_CAMPUS_POLICY_ID))
        work.visibility_after_embargo = RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID))
        work.embargo_release_date = release_date.to_s
        work.save(validate: false)
        get :destroy, id: work
      end

      context "with an active embargo" do
        let(:release_date) { Date.today+2 }

        it "deactivates embargo without updating admin_policy_id and redirects" do
          expect(work.admin_policy_id).to eq AdminPolicy::UCSB_CAMPUS_POLICY_ID
          expect(response).to redirect_to catalog_path(work)
        end
      end

      context "with an expired embargo" do
        let(:release_date) { Date.today-2 }

        it "deactivates embargo, updates the admin_policy_id and redirects" do
          expect(work.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          expect(response).to redirect_to catalog_path(work)
        end
      end
    end
  end

  describe "#update" do
    context "when I have permission to edit the object" do
      let(:release_date) { Date.today+2 }
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
        let(:release_date) { Date.today-2 }
        it "deactivates embargo, update the visibility and redirect" do
          patch :update, batch_document_ids: [work.id]
          expect(work.reload.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
          expect(response).to redirect_to embargoes_path
        end
      end
    end
  end
end
