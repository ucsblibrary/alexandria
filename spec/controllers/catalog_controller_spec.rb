require 'rails_helper'

describe CatalogController do

  describe "the search results" do
    let!(:generic_file) { GenericFile.create! }
    let!(:image) { create(:public_image) }

    it "only shows images (not GenericFiles)" do
      get :index
      found = assigns[:document_list].map(&:id)
      expect(found).to include(image.id)
      expect(found).to_not include(generic_file.id)
    end
  end

  describe "show tools" do
    it "includes the edit link" do
      expect(CatalogController.blacklight_config.show.document_actions.keys).to include :edit
    end

    it "includes the access and embargo link" do
      expect(CatalogController.blacklight_config.show.document_actions.keys).to include :access
    end
  end
end
