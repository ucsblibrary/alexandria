# frozen_string_literal: true
require "rails_helper"

describe "routes to Collection" do
  let(:collection) do
    Collection.create!(title: ["Lil' Collect"],
                       admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID)
  end

  it "uses the correct controller" do
    # Ensure that CollectionRoutingConcern is satisfied and the page is
    # rendered by the right controller
    expect(get: "/lib/ark:/99999/#{collection.id}").to(
      route_to(controller: "collections",
               action: "show",
               prot: "ark:",
               shoulder: "99999",
               id: collection.id)
    )
  end
end
