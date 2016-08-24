require 'rails_helper'

describe ApplicationHelper do
  describe '#policy_title' do
    before { AdminPolicy.ensure_admin_policy_exists }
    let(:document) { SolrDocument.new(isGovernedBy_ssim: [AdminPolicy::DISCOVERY_POLICY_ID]) }
    subject { helper.policy_title(document) }
    it { is_expected.to eq 'Discovery access only' }
  end

  describe '#linkify' do
    context 'a HTTP URL' do
      subject { helper.linkify('http://alexandria.ucsb.edu') }
      it { is_expected.to eq '<a href="http://alexandria.ucsb.edu">http://alexandria.ucsb.edu</a>' }
    end

    context 'a HTTPS URL' do
      subject { helper.linkify('https://alexandria.ucsb.edu') }
      it { is_expected.to eq '<a href="https://alexandria.ucsb.edu">https://alexandria.ucsb.edu</a>' }
    end

    context 'an ARK' do
      subject { helper.linkify('ark:/99999/fk4gx4hm1c') }
      it { is_expected.to eq 'ark:/99999/fk4gx4hm1c' }
    end
  end

  describe '#link_to_collection' do
    let(:document) { SolrDocument.new(collection_ssim: ['fk4gx4hm1c']) }
    subject { helper.link_to_collection(value: ['collection title'], document: document) }
    it { is_expected.to eq '<a href="/collections/fk4gx4hm1c">collection title</a>' }
  end
end
