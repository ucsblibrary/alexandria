# frozen_string_literal: true

require "rails_helper"

describe CurationConcernsHelper do
  describe "#url_for_document" do
    subject { helper.url_for_document(document) }

    let(:document) do
      SolrDocument.new(
        has_model_ssim: [model],
        id: "fk4v989d9j",
        identifier_ssm: ["ark:/99999/fk4v989d9j"]
      )
    end

    context "with an image" do
      let(:model) { Image.to_rdf_representation }

      it { is_expected.to eq "/lib/ark:/99999/fk4v989d9j" }
    end

    context "with an Etd" do
      let(:model) { ETD.to_rdf_representation }

      context "that has an ark" do
        it { is_expected.to eq "/lib/ark:/99999/fk4v989d9j" }
      end

      context "without an ark" do
        let(:search_state) do
          instance_double("Blacklight::SearchState", url_for_document: document)
        end

        let(:document) do
          SolrDocument.new(has_model_ssim: [model], id: "fk4v989d9j")
        end

        before do
          allow(helper).to receive(:search_state).and_return(search_state)
        end

        it { is_expected.to eq "/catalog/fk4v989d9j" }
      end
    end

    context "with a collection" do
      let(:model) { Collection.to_rdf_representation }

      it { is_expected.to eq "/collections/fk4v989d9j" }
    end

    context "a local authoritiy with a public URI" do
      let(:model) { Person.to_rdf_representation }
      let(:uri) { "http://example.com/authorities/person/fk4v989d9j" }
      let(:document) do
        SolrDocument.new(
          has_model_ssim: [model],
          id: "fk4v989d9j",
          identifier_ssm: ["ark:/99999/fk4v989d9j"],
          public_uri_ssim: [uri]
        )
      end

      it { is_expected.to eq uri }
    end
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe "#etd_url" do
    subject { helper.etd_url("123") }

    it { is_expected.to eq solr_document_url("123") }
  end

  # This is required because Blacklight 5.14 uses polymorphic_url
  # in render_link_rel_alternates
  describe "#image_url" do
    subject { helper.image_url("123") }

    it { is_expected.to eq solr_document_url("123") }
  end
end
