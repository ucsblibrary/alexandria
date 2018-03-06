# frozen_string_literal: true

require "rails_helper"

describe "Merge Record: " do
  let!(:old) { Topic.create(label: ["old record"]) }
  let!(:new) { Topic.create(label: ["new record"]) }

  context "an admin user" do
    before do
      AdminPolicy.ensure_admin_policy_exists
      allow_any_instance_of(ApplicationController).to(
        receive(:current_user).and_return(user)
      )
      allow_any_instance_of(User).to receive(:user_key).and_return("testkey")
    end

    let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

    # Test that the javascript is wired up correctly
    it "fill in and submit the form", js: true do
      visit new_merge_record_path(old)
      expect(page).to have_content "Merge Record: old record"

      # Fill in the "Merge Into" field with "record"
      element = find("input#subject_merge_target_attributes_0_hidden_label")
      element.native.send_key("record")

      within(".tt-suggestions") do
        # The suggestion list will have both records as options
        expect(page).to have_content("new record")
        expect(page).to have_content("old record")

        # Find the option that says "new record" and click it
        choice1 = find(:xpath, ".//div[1]")
        choice2 = find(:xpath, ".//div[2]")
        choice1.text == "new record" ? choice1.click : choice2.click
      end

      # A merge job should get queued when we submit the form
      expect(MergeRecordsJob).to(
        receive(:perform_later).with(old.id, new.id, "testkey")
      )

      click_button "Merge"
      expect(page).to(
        have_content("A background job has been queued to merge the records.")
      )
    end
  end
end
