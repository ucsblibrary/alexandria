# frozen_string_literal: true

require "rails_helper"

describe ETD do
  it "has system_number" do
    expect(described_class.properties).to have_key "system_number"
  end

  it "has merritt_id" do
    expect(described_class.properties).to have_key "merritt_id"
  end

  describe "::_to_partial_path" do
    subject { described_class._to_partial_path }

    it { is_expected.to eq "catalog/document" }
  end

  describe "#to_solr" do
    subject { etd.to_solr }

    let(:etd) { described_class.new(system_number: ["004092515"]) }

    it "has fields" do
      expect(subject["system_number_ssim"]).to eq ["004092515"]
    end

    describe "human_readable_type" do
      subject do
        etd.to_solr[Solrizer.solr_name("human_readable_type", :facetable)]
      end

      it { is_expected.to eq "Thesis or dissertation" }
    end

    context "under embargo" do
      let(:attrs) do
        {
          visibility_during_embargo: RDF::URI(
            ActiveFedora::Base.id_to_uri(AdminPolicy::UCSB_CAMPUS_POLICY_ID)
          ),
          embargo_release_date: Date.parse("2010-10-10"),
          visibility_after_embargo: RDF::URI(
            ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_POLICY_ID)
          ),
        }
      end
      let(:etd) { described_class.new(attrs) }

      it "has the fields" do
        expect(subject["visibility_during_embargo_ssim"]).to(
          eq "authorities/policies/ucsb_on_campus"
        )
        expect(subject["visibility_after_embargo_ssim"]).to(
          eq "authorities/policies/public"
        )
        expect(subject["embargo_release_date_dtsi"]).to(
          eq "2010-10-10T00:00:00Z"
        )
      end
    end
  end

  describe "#human_readable_type" do
    subject { described_class.new.human_readable_type }

    it { is_expected.to eq "Thesis or dissertation" }
  end

  describe "#to_partial_path" do
    subject { described_class.new.to_partial_path }

    it { is_expected.to eq "catalog/document" }
  end
end
