require 'rails_helper'

describe EtdsController do
  describe "#update" do
    let(:work) { create(:etd) }

    context "as a metadata admin" do
      before { sign_in create(:metadata_admin) }
      it "is unauthorized" do
        patch :update, id: work
        expect(response).to redirect_to root_path
      end
    end

    context "as a rights admin" do
      before do
        sign_in create(:rights_admin)
        AdminPolicy.ensure_admin_policy_exists
      end

      it "is successful" do
        patch :update, id: work, etd: {
          visibility_during_embargo: "authorities/policies/restricted",
          embargo_release_date: "2099-07-29T00:00:00+00:00",
          visibility_after_embargo: "authorities/policies/ucsb"
        }
        expect(response).to redirect_to catalog_path(work)
        expect(ActiveFedora::Base.uri_to_id(assigns[:etd].visibility_during_embargo.id)).to eq 'authorities/policies/restricted'
        expect(ActiveFedora::Base.uri_to_id(assigns[:etd].visibility_after_embargo.id)).to eq 'authorities/policies/ucsb'
      end
    end
  end
end
