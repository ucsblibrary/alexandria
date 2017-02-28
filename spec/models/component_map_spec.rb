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
end
