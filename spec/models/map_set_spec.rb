# frozen_string_literal: true
# Generated via
#  `rails generate curation_concerns:work MapSet`
require "rails_helper"

describe MapSet do
  it "includes Alexandria metadata fields" do
    expect(subject).to respond_to(:scale)
  end
  it "has an admin policy" do
    subject.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
    expect(subject.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
  end
  it "can find its attached index maps" do
    expect(subject).to respond_to(:index_maps)
  end
  it "can find its attached component maps" do
    expect(subject).to respond_to(:component_maps)
  end
end
