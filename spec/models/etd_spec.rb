require 'rails_helper'

describe ETD do
  it "has system_number" do
    expect(described_class.properties).to have_key 'system_number'
  end

  describe "#to_solr" do
    let(:etd) { described_class.new(system_number: ['004092515']) }
    subject { etd.to_solr }
    it "has fields" do
      expect(subject['system_number_ssim']).to eq ['004092515']
    end
  end

  describe "#human_readable_type" do
    subject { described_class.new.human_readable_type }
    it { is_expected.to eq 'ETD' }
  end
end
