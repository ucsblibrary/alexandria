# frozen_string_literal: true
require "rails_helper"

describe EmbargoService do
  before { AdminPolicy.ensure_admin_policy_exists }

  describe ".create_or_update_embargo" do
    let(:work) { create(:etd) }

    context "when there is no embargo" do
      it "creates embargo" do
        EmbargoService.create_or_update_embargo(work,
                                                admin_policy_id: "authorities/policies/restricted",
                                                embargo_release_date: "2099-07-29T00:00:00+00:00",
                                                visibility_after_embargo_id: "authorities/policies/ucsb")

        expect(ActiveFedora::Base.uri_to_id(work.visibility_during_embargo.id)).to eq "authorities/policies/restricted"
        expect(ActiveFedora::Base.uri_to_id(work.visibility_after_embargo.id)).to eq "authorities/policies/ucsb"
        expect(work.embargo_release_date).to eq "2099-07-29T00:00:00+00:00"
      end
    end

    context "when the etd is already under embargo" do
      let(:work) do
        create(:etd,
               visibility_during_embargo: visibility_during_embargo,
               visibility_after_embargo: visibility_after_embargo,
               embargo_release_date: 10.days.from_now)
      end

      let(:visibility_during_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/restricted")) }
      let(:visibility_after_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/public")) }

      it "updates values" do
        EmbargoService.create_or_update_embargo(work,
                                                embargo_release_date: "2099-07-29T00:00:00+00:00",
                                                visibility_after_embargo_id: "authorities/policies/ucsb")
        expect(ActiveFedora::Base.uri_to_id(work.visibility_during_embargo.id)).to eq "authorities/policies/restricted"
        expect(ActiveFedora::Base.uri_to_id(work.visibility_after_embargo.id)).to eq "authorities/policies/ucsb"
        expect(work.embargo_release_date).to eq "2099-07-29T00:00:00+00:00"
      end
    end
  end

  describe ".remove_embargo" do
    let(:work) do
      create(:etd,
             visibility_during_embargo: visibility_during_embargo,
             visibility_after_embargo: visibility_after_embargo,
             embargo_release_date: 10.days.from_now)
    end

    let(:visibility_during_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/restricted")) }
    let(:visibility_after_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/public")) }

    it "nullifies the embargo" do
      EmbargoService.remove_embargo(work)
      expect(work.embargo).to be_nil
    end
  end

  describe ".deactivate_embargo" do
    let(:vis_during_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::RESTRICTED_POLICY_ID)) }
    let(:vis_after_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID)) }

    let!(:work) do
      create(:etd,
             admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID,
             visibility_during_embargo: vis_during_embargo,
             visibility_after_embargo: vis_after_embargo,
             embargo_release_date: release_date)
    end

    before do
      EmbargoService.deactivate_embargo(work)
      work.reload
    end

    context "with an expired embargo" do
      let(:release_date) { Time.zone.today - 2 }

      it "deactivates embargo & updates ETD visibility" do
        expect(work.embargo_release_date).to be_nil
        expect(work.embargo_history).to_not be_nil
        expect(work.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
      end
    end

    context "with an active embargo" do
      let(:release_date) { Time.zone.today + 2 }

      it "deactivates embargo, but keeps old ETD visibility" do
        expect(work.embargo_release_date).to be_nil
        expect(work.embargo_history).to_not be_nil
        expect(work.admin_policy_id).to eq AdminPolicy::RESTRICTED_POLICY_ID
      end
    end
  end
end
