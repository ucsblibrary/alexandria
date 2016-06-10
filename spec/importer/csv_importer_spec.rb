require 'rails_helper'
require 'exceptions'
require 'importer'

describe Importer::CSV do
  let(:data) { Dir['spec/fixtures/images/*'] }

  context 'when the model is specified' do
    let(:csv_file) { "#{fixture_path}/csv/pamss045_with_type.csv" }

    before, after = nil
    it 'creates a new image' do
      head, tail = Importer::CSV.split(csv_file)
      expect(head.first).to eq('type')
      expect(tail.length).to eq(2)

      before = Image.all.count
      tail.each do |row|
        attrs = Importer::CSV.csv_attributes(head, row)
        files = if attrs[:files].nil?
                  []
                else
                  data.select { |d| attrs[:files].include? File.basename(d) }
                end
        VCR.use_cassette('csv_importer') do
          Importer::CSV.import(
            attributes: attrs,
            files: files
          )
        end
        after = Image.all.count
      end
      expect(after - before).to eq(1)

      img = Image.all.last
      expect(img.title).to eq ['Dirge for violin and piano (violin part)']
      expect(img.file_sets.count).to eq 4
      expect(img.file_sets.map { |d| d.files.map(&:file_name) }.flatten)
        .to eq(['dirge1.tif', 'dirge2.tif', 'dirge3.tif', 'dirge4.tif'])
      expect(img.in_collections.first.title).to eq(['Mildred Couper papers'])
    end
  end
end
