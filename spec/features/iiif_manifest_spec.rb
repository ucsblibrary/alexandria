# frozen_string_literal: true
require "rails_helper"

feature "file_set iiif manifest" do
  let(:file_path) { File.join(fixture_path, "maps", "7070s_250_u54_index.jpg") }
  let(:policy_id) { AdminPolicy::PUBLIC_POLICY_ID }
  let(:file_set) do
    FileSet.new(admin_policy_id: policy_id) do |fs|
      Hydra::Works::AddFileToFileSet.call(fs, File.new(file_path), :original_file)
    end
  end

  scenario "visit the iiif manifest" do
    visit Riiif::Engine.routes.url_helpers.info_path(file_set.id)
    expect(JSON.parse(body)["@context"]).to eql("http://iiif.io/api/image/2/context.json")
    # TODO: expect(JSON.parse(body)["width"]).to eql(some_number)
    # TODO: expect(JSON.parse(body)["height"]).to eql(some_number)
  end
end
