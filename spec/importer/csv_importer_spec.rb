require 'rails_helper'
require 'importer'
require 'importer/mods_parser'

describe Importer::CSVImporter do
  def stub_out_indexer
    # Stub out the fetch to avoid calls to external services
    allow_any_instance_of(ActiveTriples::Resource).to receive(:fetch) { 'stubbed' }
  end

  let(:image_directory) { 'spec/fixtures/images' }
  let(:csv_file) { 'spec/fixtures/csv/pamss045.csv' }
  let(:importer) { described_class.new('Image', image_directory, csv_file) }

  it 'creates new images' do
    expect(importer).to receive(:create_fedora_objects).exactly(5).times
    importer.import_all
  end
end
