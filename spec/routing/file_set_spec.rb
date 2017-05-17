# frozen_string_literal: true

require "rails_helper"

describe "FileSet routes" do
  let(:id) { "fk41234567" }

  before do
    ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists? id
    FileSet.create!(id: id)
  end

  context "download path" do
    it "finds the correct controller" do
      expect(get: Rails.application.routes.url_helpers.download_url(id, only_path: true))
        .to route_to(
          controller: "downloads",
          action: "show",
          id: id
        )
    end
  end
end
