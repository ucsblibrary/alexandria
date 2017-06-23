# frozen_string_literal: true

require "rails_helper"
require "expire_embargos"

describe ExpireEmbargos do
  before do
    AdminPolicy.ensure_admin_policy_exists
  end

  let(:visibility_during_embargo) do
    RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/restricted"))
  end

  let(:visibility_after_embargo) do
    RDF::URI(ActiveFedora::Base.id_to_uri("authorities/policies/public"))
  end

  let!(:work) do
    create(:etd,
           visibility_during_embargo: visibility_during_embargo,
           visibility_after_embargo: visibility_after_embargo,
           embargo_release_date: 10.days.ago.to_datetime)
  end

  it "clears the embargo" do
    described_class.run
    expect(work.reload.admin_policy_id).to eq "authorities/policies/public"
  end
end
