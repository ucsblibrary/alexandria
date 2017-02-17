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
end
