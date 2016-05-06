require 'rails_helper'
require 'exceptions'
require 'importer'

describe Importer::CSV do
  def stub_out_indexer
    # Stub out the fetch to avoid calls to external services
    allow_any_instance_of(ActiveTriples::Resource).to receive(:fetch) { 'stubbed' }
  end

  let(:data) { Dir['spec/fixtures/images/*'] }

  context 'when the model is passed' do
    let(:csv_file) { "#{fixture_path}/csv/pamss045.csv" }

    it 'creates 5 new images' do
      head, tail = Importer::CSV.split(csv_file)
      expect(head.first).to eq('accession_number')
      expect(tail.length).to eq(5)

      count = 0
      tail.each do |row|
        attrs = Importer::CSV.csv_attributes(head, row)
        files = if attrs[:files].nil?
                  []
                else
                  data.select { |d| attrs[:files].include? File.basename(d) }
                end
        Importer::CSV.import(
          files: files,
          model: 'Image',
          row: row,
          headers: head,
          count: count)
        count += 1
      end
      expect(count).to eq(5)
    end
  end

  # context 'when the model specified on the row' do
  #   let(:csv_file) { "#{fixture_path}/csv/pamss045_with_type.csv" }
  #   let(:importer) { described_class.new(csv_file, image_directory) }
  #   let(:collection_factory) { double }
  #   let(:image_factory) { double }

  #   it 'creates new images and collections' do
  #     expect(Importer::Factory::CollectionFactory).to receive(:new)
  #       .with(hash_excluding(:type), image_directory)
  #       .and_return(collection_factory)
  #     expect(collection_factory).to receive(:run)
  #     expect(Importer::Factory::ImageFactory).to receive(:new)
  #       .with(hash_excluding(:type), image_directory)
  #       .and_return(image_factory)
  #     expect(image_factory).to receive(:run)
  #     importer.import_all
  #   end
  # end

  # context 'when no model is specified' do
  #   let(:csv_file) { "#{fixture_path}/csv/pamss045.csv" }
  #   let(:importer) { described_class.new(csv_file, image_directory) }
  #   it 'raises an error' do
  #     expect { importer.import_all }.to raise_error(NoModelError, 'No model was specified')
  #   end
  # end

end
