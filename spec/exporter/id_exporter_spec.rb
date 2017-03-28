# frozen_string_literal: true

require "rails_helper"
require "exporter"

describe Exporter::IdExporter do
  let(:dir) { File.join("tmp", "test_exports") }
  let(:file) { "test_id_export.csv" }

  let(:exporter) { described_class.new(dir, file) }

  before do
    # Don't print exporter status messages while running tests
    allow($stdout).to receive(:puts)
  end

  it "takes an output directory and filename" do
    expect(exporter.export_dir).to eq dir
    expect(exporter.export_file_name).to eq file
    expect(exporter.export_file).to eq File.join(dir, file)
  end

  describe "#run" do
    before do
      [Image, ETD, Collection].each(&:destroy_all)
      AdminPolicy.ensure_admin_policy_exists
    end

    after { FileUtils.rm_rf(dir, secure: true) }

    # Create some records to export
    let!(:animals) do
      create(
        :collection,
        title: ["My Favorite Animals"],
        identifier: ["ark:/123/animals"],
        accession_number: ["animals_123"],
        admin_policy_id: AdminPolicy::PUBLIC_POLICY_ID
      )
    end
    let!(:puppies) do
      create(
        :image,
        title: ["Puppies"],
        identifier: ["ark:/123/puppies"],
        accession_number: ["puppies_123"],
        admin_policy_id: AdminPolicy::RESTRICTED_POLICY_ID
      )
    end
    let!(:kitties) do
      create(
        :image,
        title: ["Kitties"],
        identifier: ["ark:/123/kitties"],
        accession_number: ["kitties_123"],
        admin_policy_id: AdminPolicy::UCSB_CAMPUS_POLICY_ID
      )
    end
    let!(:etd) do
      ETD.create!(
        title: ["Cute Animals Thesis"],
        identifier: ["ark:/123/thesis"],
        accession_number: ["thesis_123"],
        admin_policy_id: AdminPolicy::PUBLIC_CAMPUS_POLICY_ID
      )
    end

    let(:headers) do
      %w(
        type
        id
        accession_number
        identifier
        title
        access_policy
      )
    end

    it "exports the records" do
      exporter.run

      export_file = File.join(dir, file)
      contents = File.readlines(export_file).map(&:strip)

      # The file should have 5 lines total
      expect(contents.count).to eq 5

      expect(contents[0].split(",")).to eq headers

      expect(contents[1].split(",")).to(
        eq([
             "Collection",
             animals.id,
             animals.accession_number.first,
             animals.ark,
             animals.title.first,
             "public",
           ])
      )

      # The Image records may be in any order
      line2 = contents[2].split(",")
      line3 = contents[3].split(",")

      expect([line2, line3]).to(
        contain_exactly(
          [
            "Image",
            puppies.id,
            puppies.accession_number.first,
            puppies.ark,
            puppies.title.first,
            "restricted",
          ],
          [
            "Image",
            kitties.id,
            kitties.accession_number.first,
            kitties.ark,
            kitties.title.first,
            "ucsb_campus",
          ]
        )
      )

      expect(contents[4].split(",")).to(
        eq([
             "ETD",
             etd.id,
             etd.accession_number.first,
             etd.ark,
             etd.title.first,
             "public_campus",
           ])
      )
    end
  end # run
end
