# frozen_string_literal: true

require "rails_helper"

describe CatalogController do
  before do
    AdminPolicy.ensure_admin_policy_exists
    allow(controller).to receive(:current_user).and_return(user)
  end

  let(:user) { nil }

  describe "the search results" do
    let!(:file_set) { FileSet.create! }
    let!(:image) { create(:public_image) }

    it "only shows images (not FileSets)" do
      get :index
      found = assigns[:document_list].map(&:id)
      expect(found).to include(image.id)
      expect(found).not_to include(file_set.id)
    end
  end

  describe "show tools" do
    it "includes the edit link" do
      expect(described_class.blacklight_config.show.document_actions.keys).to(
        include(:edit)
      )
    end

    it "includes the access and embargo link" do
      expect(described_class.blacklight_config.show.document_actions.keys).to(
        include(:access)
      )
    end
  end

  describe "show page" do
    let(:ark) { "ark:/99999/123" }

    context "download TTL file" do
      before do
        get :show, params: { id: record, format: :ttl }
      end

      context "for an Image record" do
        let(:record) { create :public_image, identifier: [ark] }

        it "shows public urls (not fedora urls)" do
          expect(response.body).to include "<http://test.host/lib/#{ark}>"
        end
      end

      context "for an ETD record" do
        let(:record) { create :public_etd, identifier: [ark] }

        it "shows public urls (not fedora urls)" do
          expect(response.body).to include "<http://test.host/lib/#{ark}>"
        end
      end

      context "for a record with no ark" do
        let(:record) { create :public_image, identifier: nil }

        it "shows public urls (not fedora urls)" do
          expect(response.body).to(
            include("<http://test.host/catalog/#{record.id}>")
          )
        end
      end
    end

    context "view a restricted file" do
      let(:restricted_image) { create(:image, :restricted) }

      context "logged in as an admin user" do
        let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

        before do
          get :show, params: { id: restricted_image }
        end

        it "is successful" do
          expect(response).to be_successful
          expect(response).to render_template(:show)
        end
      end

      context "logged in as a UCSB user" do
        let(:user) { user_with_groups [AdminPolicy::UCSB_GROUP] }

        before do
          get :show, params: { id: restricted_image }
        end

        it "access is denied" do
          expect(response).to redirect_to root_url
          expect(flash[:alert]).to(
            match(/You do not have sufficient access privileges/)
          )
        end
      end
    end

    context "bad URL" do
      it "returns a 404" do
        get :show, params: { id: "fk4cn8cc3d" }
        expect(response.response_code).to eq 404
        expect(response).to render_template("errors/not_found")
      end
    end
  end # show page

  describe "#editor?" do
    subject { controller.editor?(nil, document: SolrDocument.new) }

    context "for an admin" do
      let(:user) { user_with_groups [AdminPolicy::META_ADMIN] }

      it { is_expected.to be true }
    end

    context "for a non-admin user" do
      it { is_expected.to be false }
    end
  end
end
