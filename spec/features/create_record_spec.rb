# frozen_string_literal: true

require "rails_helper"

describe "Group creation" do
  context "a metadata admin" do
    before do
      AdminPolicy.ensure_admin_policy_exists
      allow_any_instance_of(User).to(
        receive(:groups).and_return([AdminPolicy::META_ADMIN])
      )
    end

    it "creates a new record" do
      visit search_catalog_path
      click_link "Add Record"
      select "Group", from: "type"
      click_button "Next"
      title = "My New Group"
      fill_in "Name", with: title
      expect { click_button "Save" }.to change(Group, :count).by(1)
      expect(page).to have_content title
    end
  end
end
