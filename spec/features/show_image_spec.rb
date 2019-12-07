# frozen_string_literal: true

require "rails_helper"

describe "Image show page:" do
  # TODO: Add test that ensures URIs are being dereferenced before display
  # let(:creator) { ['http://id.loc.gov/authorities/names/n81038526'] }
  let(:creator) { ["Century Company"] }
  let(:extent) { ["1 map : color ; 27 x 38 cm"] }
  let(:scale) { ["1:18,374,400"] }

  let(:title) do
    ["Region around the North Pole : "\
     "giving the records of the most important explorations"]
  end

  let(:collection) do
    create(:collection,
           title: ["HECK"],
           identifier: ["ark:/99999/YES"])
  end

  let(:image) do
    create(:image,
           admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
           creator: creator,
           extent: extent,
           local_collection_id: [collection.id],
           scale: scale,
           title: title)
  end

  let(:image_without_collection) do
    create(:image,
           admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID,
           title: title)
  end

  let(:file_path) { File.join(fixture_path, "images", "cusbspcmss36_110108_1_a.tif") }

  let(:file_set) do
    FileSet.new(admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID) do |fs|
      Hydra::Works::AddFileToFileSet.call(
        fs,
        File.new(file_path),
        :original_file
      )
    end
  end

  # See config/routes.rb: routing for images is a little weird
  it "show the page for the regular image" do
    visit catalog_ark_path("ark:", "99999", image.id)

    expect(page).to have_content extent.first
    expect(page).to have_content creator.first
    expect(page).to have_content scale.first
    expect(page).to have_content title.first
  end

  describe "viewing images allows for pan and zoom" do
    before do
      allow_any_instance_of(SolrDocument).to receive(:ark).and_return("99999")
      image.ordered_members << file_set
      image.save!
      image.update_index
    end

    context "page doesn't use openseadragon picture tag with pdfs" do
      let(:file_path) { File.join(fixture_path, "pdf", "sample.pdf") }

      it "with a pdf" do
        visit catalog_ark_path("ark:", "99999", image.id)
        expect(page).not_to have_css("picture")
      end
    end

    context "page uses openseadragon picture tag with a tif" do
      it "with a tif" do
        visit catalog_ark_path("ark:", "99999", image.id)
        expect(page).to have_css("picture")
      end
    end
  end

  it "show the page for the image missing a collection" do
    visit catalog_ark_path("ark:", "99999", image_without_collection.id)

    expect(page).to have_content title.first
  end
end
