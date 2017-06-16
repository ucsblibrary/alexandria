# frozen_string_literal: true

require "rails_helper"

describe SolrDocument do
  before do
    ActiveFedora::SolrService.add([map_set, index_map, component_map])
    ActiveFedora::SolrService.commit
  end

  let(:image) { create(:image) }

  let(:document) do
    SolrDocument.new(
      id: image.id,
      identifier_ssm: ["ark:/99999/fk4v989d9j"],
      has_model_ssim: [Image.to_rdf_representation]
    )
  end

  let(:etd_document) do
    SolrDocument.new(id: "foobar", has_model_ssim: [ETD.to_rdf_representation])
  end

  let(:map_set) do
    SolrDocument.new(id: "mapset",
                     component_maps_ssim: ["componentmap"],
                     index_maps_ssim: ["indexmap"],
                     has_model_ssim: ["MapSet"])
  end

  let(:index_map) do
    SolrDocument.new(id: "indexmap",
                     accession_number_ssim: ["indexmap"],
                     has_model_ssim: ["IndexMap"])
  end

  let(:component_map) do
    SolrDocument.new(id: "componentmap",
                     accession_number_ssim: ["componentmap"],
                     index_maps_ssim: ["indexmap"],
                     parent_id_ssim: ["mapset"],
                     has_model_ssim: ["ComponentMap"])
  end

  context "for an image" do
    describe "#ark" do
      subject { document.ark }
      it { is_expected.to eq "ark:/99999/fk4v989d9j" }
    end

    describe "#etd?" do
      subject { document.etd? }
      it { is_expected.to be false }
    end

    describe "#public_uri" do
      subject { document.public_uri }
      it { is_expected.to be nil }
    end
  end

  context "for an etd" do
    describe "#etd?" do
      subject { etd_document.etd? }
      it { is_expected.to be true }
    end

    describe "file_sets" do
      subject { etd_document.file_sets }
      context "with file sets" do
        let(:file_set_document) do
          SolrDocument.new(
            id: "bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3"
          )
        end

        before do
          etd_document["member_ids_ssim"] = [file_set_document.id]
          ActiveFedora::SolrService.add(file_set_document)
          ActiveFedora::SolrService.commit
        end

        it "looks up the file sets" do
          expect(subject.map(&:id)).to eq [file_set_document.id]
        end
      end

      context "without file sets" do
        it { is_expected.to be_empty }
      end
    end
  end

  describe "#to_param" do
    let(:noid) { "f123456789" }
    let(:id)   { "f123456789" }

    subject { document.to_param }

    context "for an object with an ARK" do
      let(:document) do
        SolrDocument.new(id: id, identifier_ssm: ["ark:/99999/#{noid}"])
      end

      it "converts the ark to a noid" do
        expect(subject).to eq noid
      end
    end

    context "for an object without an ARK" do
      let(:document) { SolrDocument.new(id: id, identifier_ssm: nil) }
      it "converts the id to a noid" do
        expect(subject).to eq noid
      end
    end
  end

  describe "#after_embargo_status" do
    before { AdminPolicy.ensure_admin_policy_exists }
    let(:document) do
      SolrDocument.new(
        visibility_during_embargo_ssim: ["authorities/policies/ucsb_on_campus"],
        visibility_after_embargo_ssim: ["authorities/policies/public"],
        embargo_release_date_dtsi: "2010-10-10T00:00:00Z"
      )
    end
    subject { document.after_embargo_status }
    it { is_expected.to eq " - Becomes Public access on 10/10/2010" }
  end

  describe "#curation_concern?" do
    let(:collection) do
      SolrDocument.new(has_model_ssim: ["Collection"])
    end

    it "identifies correctly" do
      expect(SolrDocument.new.curation_concern?).to eq false
      expect(collection.curation_concern?).to eq false
      expect(component_map.curation_concern?).to eq true
      expect(document.curation_concern?).to eq true
      expect(etd_document.curation_concern?).to eq true
      expect(index_map.curation_concern?).to eq true
      expect(map_set.curation_concern?).to eq true
    end
  end

  describe "#map_sets" do
    context "called on a MapSet" do
      # They won't be the very same SolrDocument
      subject { map_set.map_sets.map(&:id) }

      it { is_expected.to eq [map_set.id] }
    end

    context "called on an IndexMap" do
      subject { index_map.map_sets.map(&:id) }

      it { is_expected.to eq [map_set.id] }
    end

    context "called on a ComponentMap" do
      subject { component_map.map_sets.map(&:id) }

      it { is_expected.to eq [map_set.id] }
    end
  end

  describe "#index_maps" do
    context "called on a MapSet" do
      # They won't be the very same SolrDocument
      subject { map_set.index_maps.map(&:id) }

      it { is_expected.to eq [index_map.id] }
    end

    context "called on an IndexMap" do
      subject { index_map.index_maps }

      it { is_expected.to be_empty }
    end

    context "called on a ComponentMap" do
      subject { component_map.index_maps.map(&:id) }

      it { is_expected.to eq [index_map.id] }
    end
  end

  describe "#component_maps" do
    let(:map_set) do
      SolrDocument.new(
        id: "mapset",
        component_maps_ssim: (0..1500).map { |i| "componentmap_#{i}" },
        index_maps_ssim: ["indexmap"],
        has_model_ssim: ["MapSet"]
      )
    end

    let(:component_maps) do
      (0..1500).map do |i|
        SolrDocument.new(id: "componentmap_#{i}",
                         accession_number_ssim: "componentmap_#{i}",
                         parent_id_ssim: ["mapset"],
                         has_model_ssim: ["ComponentMap"])
      end
    end

    before do
      ActiveFedora::SolrService.add(component_maps)
      ActiveFedora::SolrService.commit
    end

    context "called on a MapSet" do
      # They won't be the very same SolrDocument
      subject { map_set.component_maps.map(&:id) }

      it { is_expected.to eq((0..1500).map { |i| "componentmap_#{i}" }.sort) }
    end

    context "called on an IndexMap" do
      subject { index_map.component_maps.map(&:id) }

      it { is_expected.to eq((0..1500).map { |i| "componentmap_#{i}" }.sort) }
    end

    context "called on a ComponentMap" do
      subject { component_map.component_maps.map(&:id) }

      it { is_expected.to eq((0..1500).map { |i| "componentmap_#{i}" }.sort) }
    end
  end
end
