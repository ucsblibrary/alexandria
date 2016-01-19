require 'rails_helper'

describe ApplicationHelper do
  describe '#policy_title' do
    before { AdminPolicy.ensure_admin_policy_exists }
    let(:document) { SolrDocument.new(isGovernedBy_ssim: [AdminPolicy::DISCOVERY_POLICY_ID]) }
    subject { helper.policy_title(document) }
    it { is_expected.to eq 'Discovery access only' }
  end

  describe '#link_to_collection' do
    let(:document) { SolrDocument.new(collection_ssim: ['fk/4g/x4/hm/fk4gx4hm1c']) }
    subject { helper.link_to_collection(value: ['collection title'], document: document) }
    it { is_expected.to eq '<a href="/collections/fk4gx4hm1c">collection title</a>' }
  end
end
