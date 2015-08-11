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

    context "under embargo" do
      let(:attrs) do
        {
          visibility_during_embargo: RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::UCSB_CAMPUS_POLICY_ID)),
          embargo_release_date: Date.parse('2010-10-10'),
          visibility_after_embargo: RDF::URI(ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID))
        }
      end
      let(:etd) { ETD.new(attrs) }

      it "has the fields" do
        expect(subject['visibility_during_embargo_ssim']).to eq 'authorities/policies/ucsb_on_campus'
        expect(subject['visibility_after_embargo_ssim']).to eq 'authorities/policies/public'
        expect(subject['embargo_release_date_dtsi']).to eq '2010-10-10T00:00:00Z'
      end


    end
  end

  describe "#human_readable_type" do
    subject { described_class.new.human_readable_type }
    it { is_expected.to eq 'ETD' }
  end

  describe "#to_partial_path" do
    subject { described_class.new.to_partial_path }
    it { is_expected.to eq 'catalog/document' }
  end

end
