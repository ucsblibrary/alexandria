require 'rails_helper'
require 'importer'

describe Importer::CSV do
  before { Image.destroy_all }

  let(:data) { Dir['spec/fixtures/images/*'] }

  context 'when the model is specified' do
    let(:metadata) { ["#{fixture_path}/csv/pamss045.csv"] }

    it 'creates a new image' do
      VCR.use_cassette('csv_importer') do
        Importer::CSV.import(
          metadata, data, skip: 0
        )
      end
      expect(Image.count).to eq(1)

      img = Image.first
      expect(img.title).to eq ['Dirge for violin and piano (violin part)']
      expect(img.file_sets.count).to eq 4
      expect(img.file_sets.map { |d| d.files.map(&:file_name) }.flatten)
        .to eq(['dirge1.tif', 'dirge2.tif', 'dirge3.tif', 'dirge4.tif'])
      expect(img.in_collections.first.title).to eq(['Mildred Couper papers'])
      expect(img.license.first.rdf_label).to eq ['In Copyright']
    end
  end
end
