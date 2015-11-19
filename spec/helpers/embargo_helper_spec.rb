require 'rails_helper'

describe EmbargoHelper do
  let(:policy_after_embargo) { AdminPolicy::RESTRICTED_POLICY_ID }
  let(:uri) { RDF::URI(ActiveFedora::Base.id_to_uri(policy_after_embargo)) }

  let(:etd) { build(:etd, visibility_after_embargo: uri) }

  before { AdminPolicy.ensure_admin_policy_exists }

  describe 'after_visibility' do
    subject { helper.after_visibility(etd) }
    it { is_expected.to eq 'Restricted access' }
  end
end
