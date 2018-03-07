# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::MODS do
  let(:data) { Dir["#{fixture_path}/images/cusbspcmss36*.tif"] }
  let(:metadata) { ["#{fixture_path}/mods/cusbspcmss36_110108.xml"] }

  before do
    # Don't fetch external records during specs
    allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external)
  end

  describe "#import an Image" do
    context "without an existing collection" do
      before do
        VCR.use_cassette("mods_importer") do
          if ActiveFedora::Base.exists? "fk41234567"
            ActiveFedora::Base.find("fk41234567").destroy(eradicate: true)
          end
          if ActiveFedora::Base.exists? "fk49876543"
            ActiveFedora::Base.find("fk49876543").destroy(eradicate: true)
          end

          Collection.destroy_all
          Image.destroy_all
          FileSet.destroy_all
        end
      end

      it "creates a new image, files, and a collection" do
        VCR.use_cassette("mods_importer") do
          described_class.import(
            meta: metadata,
            data: data,
            options: { skip: 0 }
          )
        end

        expect(Image.count).to eq 1
        expect(FileSet.count).to eq 2
        expect(Collection.count).to eq 1

        image = Image.first
        original = image.file_sets.select do |fs|
          fs.original_file.original_name == "cusbspcmss36_110108_1_a.tif"
        end.first
        expect(original.mime_type).to eq "image/tiff"

        # Image.reload doesn't clear @file_association
        reloaded = Image.find(image.id)
        expect(reloaded.file_sets.first).not_to be_nil

        expect(reloaded.identifier.first).to match %r{^ark:/99999/fk4\w{7}$}

        expect(reloaded.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

        coll = reloaded.in_collections.first
        expect(coll.accession_number).to eq ["SBHC Mss 36"]
        expect(coll.title).to eq ["Santa Barbara picture postcards collection"]
        expect(coll.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

        solr_doc = ActiveFedora::SolrService.query("id:#{image.id}").first
        expect(solr_doc["collection_label_ssim"]).to(
          eq ["Santa Barbara picture postcards collection"]
        )
      end
    end

    context "when the collection already exists" do
      before do
        Image.all.each { |i| i.destroy(eradicate: true) }
        Collection.all.each { |c| c.destroy(eradicate: true) }
      end

      let!(:coll) do
        Collection.create!(
          accession_number: ["SBHC Mss 36"],
          title: ["Test Collection"]
        )
      end

      it "adds image to existing collection" do
        expect do
          VCR.use_cassette("mods_importer") do
            described_class.import(
              meta: metadata,
              data: data,
              options: { skip: 0 }
            )
          end
        end.to change(Collection, :count).by(0)

        expect(Image.count).to eq 1
        image = Image.first
        expect(image.local_collection_id).to eq [coll.id]
      end
    end
  end

  describe "#import a Collection" do
    let(:metadata) do
      ["#{fixture_path}/mods/sbhcmss78_FlyingAStudios_collection.xml"]
    end

    context "when the collection does not exist" do
      before do
        Collection.all.each { |c| c.destroy(eradicate: true) }
        Image.all.each { |i| i.destroy(eradicate: true) }
      end

      it "creates a collection" do
        expect do
          VCR.use_cassette("mods_importer") do
            described_class.import(
              meta: metadata,
              data: data,
              options: { skip: 0 }
            )
          end
        end.to(
          change(Collection, :count).by(1).and(
            change(Person, :count).by(1)
          )
        )

        coll = Collection.first

        expect(coll.id).to match(/^fk4\w{7}$/)
        expect(coll.accession_number).to eq ["SBHC Mss 78"]
        expect(coll.title).to(
          eq ["Joel Conway / Flying A Studio photograph collection"]
        )
        expect(coll.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

        expect(coll.collector.count).to eq 1
        uri = coll.collector.first.rdf_subject.value
        collector = Person.find(Person.uri_to_id(uri))
        expect(collector.foaf_name).to eq "Conway, Joel"
      end
    end

    context "when the collection already exists" do
      before do
        Collection.all.each { |c| c.destroy(eradicate: true) }
        Image.all.each { |i| i.destroy(eradicate: true) }
      end

      let!(:existing) do
        Collection.create!(
          accession_number: ["SBHC Mss 78"],
          title: ["Test Collection"]
        )
      end

      it "adds metadata to existing collection" do
        expect do
          VCR.use_cassette("mods_importer") do
            described_class.import(
              meta: metadata,
              data: data,
              options: { skip: 0 }
            )
          end
        end.to change(Collection, :count).by(0)

        coll = Collection.first
        expect(coll.id).to eq existing.id
        expect(coll.accession_number).to eq ["SBHC Mss 78"]
        expect(coll.title).to(
          eq ["Joel Conway / Flying A Studio photograph collection"]
        )
      end
    end

    context "when the person already exists" do
      before do
        Collection.all.each { |c| c.destroy(eradicate: true) }
        Person.destroy_all
      end
      let!(:existing) { Person.create(foaf_name: "Conway, Joel") }

      it "doesn't create another person" do
        expect do
          VCR.use_cassette("mods_importer") do
            described_class.import(
              meta: metadata,
              data: data,
              options: { skip: 0 }
            )
          end
        end.to(
          change(Collection, :count).by(1).and(
            change(Person, :count).by(0)
          )
        )

        coll = Collection.first
        expect(coll.collector.count).to eq 1
        uri = coll.collector.first.rdf_subject.value
        collector = Person.find(Person.uri_to_id(uri))
        expect(collector.id).to eq existing.id
      end
    end
  end

  describe "fields that have Strings instead of URIs" do
    let(:metadata) do
      ["#{fixture_path}/mods/sbhcmss78_FlyingAStudios_collection.xml"]
    end

    let(:frodo) { "Frodo Baggins" }
    let(:bilbo) { "Bilbo Baggins" }
    let(:pippin) do
      { _rdf: ["http://id.loc.gov/authorities/names/pippin"] }
    end

    context "when rights_holder has strings or uris" do
      before do
        Agent.delete_all
        Agent.create(foaf_name: frodo) # existing rights holder
        allow_any_instance_of(Parse::MODS).to(
          receive(:rights_holder) { [frodo, bilbo, pippin] }
        )
      end

      it "finds or creates the rights holders" do
        expect do
          VCR.use_cassette("mods_importer") do
            described_class.import(
              meta: metadata,
              data: data,
              options: { skip: 0 }
            )
          end
        end.to change { Agent.exact_model.count }.by(1)

        rights_holders = Agent.exact_model
        expect(rights_holders.map(&:foaf_name).sort).to eq [bilbo, frodo]
      end
    end
  end
end
