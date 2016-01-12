require 'rails_helper'
require 'importer'
require 'importer/mods_parser'

describe Importer::CSVImporter do
  def stub_out_indexer
    # Stub out the fetch to avoid calls to external services
    allow_any_instance_of(ActiveTriples::Resource).to receive(:fetch) { 'stubbed' }
  end

  let(:image_directory) { 'spec/fixtures/images' }

  context 'when the model is passed' do
    let(:csv_file) { "#{fixture_path}/csv/pamss045.csv" }
    let(:importer) { described_class.new(csv_file, image_directory, Image) }
    it 'creates new images' do
      expect(importer).to receive(:create_fedora_objects).exactly(5).times
      importer.import_all
    end
  end

  context 'when the model specified on the row' do
    let(:csv_file) { "#{fixture_path}/csv/pamss045_with_type.csv" }
    let(:importer) { described_class.new(csv_file, image_directory) }
    it 'creates new images and collections' do
      expect_any_instance_of(Importer::Factory::CollectionFactory).to receive(:run)
      expect_any_instance_of(Importer::Factory::ImageFactory).to receive(:run)
      importer.import_all
    end
  end
end
