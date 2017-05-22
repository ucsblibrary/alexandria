# frozen_string_literal: true

require "rails_helper"

feature "Editing Records", js: true do
  let!(:collection) do
    Collection.create!(
      title: ["superbork"],
      identifier: ["ark:/99999/smh"],
      id: "blahbhbhbh"
    )
  end

  let!(:record) do
    VCR.use_cassette("image_factory") do
      create(:public_image,
             created_attributes: [{ start: ["2000"], finish: ["2010"] }],
             local_collection_id: ["blahbhbhbh"],
             id: "bork",
             lc_subject: [RDF::URI("http://id.loc.gov/authorities/subjects/sh90003868")],
             title: ["I am real and not fake"])
    end
  end

  let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

  context "as an admin user" do
    before do
      allow_any_instance_of(CollectionsController).to receive(:current_user).and_return(user)
      allow_any_instance_of(CatalogController).to receive(:current_user).and_return(user)
      allow_any_instance_of(RecordsController).to receive(:current_user).and_return(user)
    end

    scenario "edits a record" do
      VCR.use_cassette("image_factory") do
        visit catalog_ark_path("ark:", "99999", "bork")

        expect(page).to have_content "I am real and not fake"
        expect(page).to have_content "2000 - 2010"

        click_link "Edit Metadata"
        expect(page).to have_content "Edit I am real and not fake"

        expect(page).to have_selector("input[value='I am real and not fake']")
        expect(page).to(
          have_selector("input[value='http://id.loc.gov/authorities/subjects/sh90003868']")
        )

        fill_in "Title", with: "OK I'm fake"
        first("#image_created_attributes_0_hidden_label").set "1999"

        click_button "Save"
        expect(page).to have_content "OK I'm fake"
        expect(page).to have_content "1999 - 2010"
        expect(record.reload.title).to eq ["OK I'm fake"]
      end
    end
  end
end
