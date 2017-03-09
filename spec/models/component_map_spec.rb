# frozen_string_literal: true
# Generated via
#  `rails generate curation_concerns:work ComponentMap`
require "rails_helper"

describe ComponentMap do
  it "includes Alexandria metadata fields" do
    expect(subject).to respond_to(:scale)
  end
  it "has an admin policy" do
    subject.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
    expect(subject.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
  end
  it "can be attached to a parent object (MapSet)" do
    expect(subject).to respond_to(:parent_id)
  end
  it "can be attached to an index map" do
    expect(subject).to respond_to(:index_map_id)
  end

  describe "#to_solr" do
    let(:image) { build(:image, accession_number: ["acc 1"]) }
    let(:solr_hash) { image.to_solr }

    it "includes a sortable accession number" do
      expect(solr_hash["accession_number_si"]).to eq "acc 1"
    end
  end
end
