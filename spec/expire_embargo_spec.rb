require 'rails_helper'
require 'expire_embargos'

describe ExpireEmbargos do
  before { AdminPolicy.ensure_admin_policy_exists }
  let!(:work) do
    create(:etd,
           visibility_during_embargo: visibility_during_embargo,
           visibility_after_embargo: visibility_after_embargo,
           embargo_release_date: 10.days.ago.to_datetime)
  end

  let(:visibility_during_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri('authorities/policies/restricted')) }
  let(:visibility_after_embargo) { RDF::URI(ActiveFedora::Base.id_to_uri('authorities/policies/public')) }

  it 'clears the embargo' do
    expect(described_class.run).to eq 1
    expect(work.reload.admin_policy_id).to eq 'authorities/policies/public'
  end
end
