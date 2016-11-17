# frozen_string_literal: true

require "rails_helper"

feature "Editing Records", js: true do
  let(:record) { Topic.create(label: ["old label"]) }
  let(:new_label) { "New label" }

  context "an admin user" do
    before do
      AdminPolicy.ensure_admin_policy_exists
      allow_any_instance_of(User).to receive(:groups).and_return([AdminPolicy::META_ADMIN])
    end

    scenario "edits a record" do
      visit topic_path(record)
      click_link "Edit Metadata"
      fill_in "Label", with: new_label
      click_button "Save"
      expect(page).to have_content new_label
      expect(record.reload.label).to eq [new_label]
    end
  end
end
