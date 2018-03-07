# frozen_string_literal: true

require "rails_helper"
require "object_factory_writer"

describe ObjectFactoryWriter do
  let(:files_dirs) { [] }
  let(:logger) { Logger.new(STDOUT) }
  let(:settings) { { files_dirs: files_dirs, logger: logger } }
  let(:writer) { described_class.new(settings) }

  before do
    # Don't fetch external records during specs
    allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external)
  end

  describe "#put" do
    before { ETD.destroy_all }

    let(:traject_context) do
      instance_double("Traject::Indexer::Context", output_hash: traject_hash)
    end

    let(:traject_hash) do
      {
        "author" => ["Valerie"],
        "created_start" => ["2013"],
        "degree_grantor" => [
          "University of California, Santa Barbara Mathematics",
        ],
        # Literal newline characters since that's how we store
        # paragraphs, in order to preserve order despite RDF
        "description" => [
          "Marine mussels use a mixture of proteins...\n\n"\
          "The performance of strong adhesion...",
        ],
        "dissertation_degree" => [],
        "dissertation_institution" => [],
        "dissertation_year" => [],
        "extent" => ["1 online resource (147 pages)"],
        "filename" => ["My_stuff.pdf"],
        "fulltext_link" => [],
        "id" => ["bork"],
        "isbn" => ["1234"],
        "issued" => ["2013"],
        "names" => ["Paul", "Frodo Baggins", "Hector"],
        "place_of_publication" => ["[Santa Barbara, Calif.]"],
        "publisher" => ["University of California, Santa Barbara"],
        # intentionally weird capitalization
        "relators" => ["degree supervisor.", "adventurer", "Degree suPERvisor"],
        "system_number" => [],
        "title" => ["How to be awesome"],
        "work_type" => [{ _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/txt"] }],
      }
    end

    it "calls the etd factory" do
      VCR.use_cassette("etd_importer") do
        writer.put(traject_context.output_hash)
      end

      etd = ETD.first
      expect(etd.author).to eq ["Valerie"]
      expect(etd.degree_grantor).to(
        eq(["University of California, Santa Barbara Mathematics"])
      )
      expect(etd.degree_supervisor).to contain_exactly("Paul", "Hector")
      expect(etd.description).to(
        eq([
             "Marine mussels use a mixture of proteins...\n\n"\
             "The performance of strong adhesion...",
           ])
      )
      expect(etd.extent).to eq ["1 online resource (147 pages)"]
      expect(etd.fulltext_link).to eq []
      expect(etd.isbn).to eq ["1234"]
      expect(etd.issued).to eq ["2013"]
      expect(etd.language).to eq []
      expect(etd.place_of_publication).to eq ["[Santa Barbara, Calif.]"]
      expect(etd.publisher).to eq ["University of California, Santa Barbara"]
      expect(etd.title).to eq ["How to be awesome"]
      expect(etd.work_type.first.class).to(
        eq ControlledVocabularies::ResourceType
      )
    end
  end

  describe "#find_files_to_attach" do
    subject { writer.find_files_to_attach(attrs) }

    let(:attrs) do
      {
        fulltext_link: [
          "http://library.ucsb.edu/OBJID/Cylinder12783",
          "http://library.ucsb.edu/OBJID/Cylinder0001",
        ],
      }
    end

    context "with ETDs" do
      # rubocop:disable Metrics/LineLength
      let(:settings) do
        {
          "etd" => {
            xml: "/var/folders/81/3r2q3gb16x710qjpdsdhc3c40000gn/T/d20160811-32702-18ce4a4/etdadmin_upload_114151.zip/Scholl_ucsb_0035D_10935_DATA.xml",
            pdf: "/var/folders/81/3r2q3gb16x710qjpdsdhc3c40000gn/T/d20160811-32702-18ce4a4/etdadmin_upload_114151.zip/Scholl_ucsb_0035D_10935.pdf",
            supplements: [],
          },
        }
      end

      it "returns the correct hash" do
        expect(subject).to(
          eq(
            "xml" => "/var/folders/81/3r2q3gb16x710qjpdsdhc3c40000gn/T/d20160811-32702-18ce4a4/etdadmin_upload_114151.zip/Scholl_ucsb_0035D_10935_DATA.xml",
            "pdf" => "/var/folders/81/3r2q3gb16x710qjpdsdhc3c40000gn/T/d20160811-32702-18ce4a4/etdadmin_upload_114151.zip/Scholl_ucsb_0035D_10935.pdf",
            "supplements" => []
          )
        )
      end
      # rubocop:enable Metrics/LineLength
    end

    context "with a single directory" do
      let(:files_dirs) { [File.join(fixture_path, "cylinders", "cyl1-2")] }

      it "contains the correct files" do
        expect(subject.count).to eq 1 # It's an array of arrays
        expect(subject.first).to(
          include(File.join(files_dirs, "cusb-cyl0001a.wav"),
                  File.join(files_dirs, "cusb-cyl0001b.wav"))
        )
      end
    end

    context "with more than one directory" do
      let(:files_dirs) do
        [
          File.join(fixture_path, "cylinders", "cyl1-2"),
          File.join(fixture_path, "cylinders", "cyl3-"),
        ]
      end

      it "contains the correct files, grouped by cylinder" do
        expect(subject.count).to eq 2

        expect(subject[0]).to(
          include(File.join(files_dirs.last, "cusb-cyl12783a.wav"),
                  File.join(files_dirs.last, "cusb-cyl12783b.wav"))
        )

        expect(subject[1]).to(
          include(File.join(files_dirs.first, "cusb-cyl0001a.wav"),
                  File.join(files_dirs.first, "cusb-cyl0001b.wav"))
        )
      end
    end

    context "with a bad cylinder name" do
      let(:attrs) { { fulltext_link: ["PA Mss 42"] } }
      let(:files_dirs) { [File.join(fixture_path, "cylinders")] }

      it "continues without an error" do
        expect(subject.count).to eq 0
      end
    end
  end
end
