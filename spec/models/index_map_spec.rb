# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work IndexMap`
require "rails_helper"

describe IndexMap do
  it "includes Alexandria metadata fields" do
    subject.scale = ["1:300,000"]
    expect(subject.scale).to eql(["1:300,000"])
  end
  it "has an admin policy" do
    subject.admin_policy_id = AdminPolicy::PUBLIC_POLICY_ID
    expect(subject.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
  end
  it "can be attached to a parent object (MapSet)" do
    expect(subject).to respond_to(:parent_id)
  end
  it "can get any ComponentMaps that are attached to it" do
    expect(subject).to respond_to(:component_maps)
  end
end
