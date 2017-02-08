# coding: utf-8
require 'rails_helper'
require 'importer'

describe Importer::CSV do
  before { Image.destroy_all }
  let(:logfile) { "#{fixture_path}/logs/csv_import.log" }
  before(:example) do
    Importer::CSV.log_location(logfile)
  end

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
        .to contain_exactly('dirge1.tif',
                            'dirge2.tif',
                            'dirge3.tif',
                            'dirge4.tif')
      expect(img.in_collections.first.title).to eq(['Mildred Couper papers'])
      expect(img.license.first.rdf_label).to eq ['In Copyright']
    end
  end

  context "#split" do
    let(:csvfile) { "#{fixture_path}/csv/pamss045.csv" }
    let(:utf8problemfile) { "#{fixture_path}/csv/mcpeak-utf8problems.csv" }

    it "reads in a known CSV file" do
      expect(Importer::CSV.split(csvfile)).to be_instance_of(Array)
    end

    it "reads in a CSV file with UTF-8 problems" do
      expect(Importer::CSV.split(utf8problemfile)).to be_instance_of(Array)
    end

    let(:brazilmap) { "#{fixture_path}/csv/brazil.csv" }
    # DIGREPO-676 Row 4 title should read as "Rio Xixé" with an accent over the final e.
    it "reads in diacritics properly" do
      expect(Importer::CSV.split(brazilmap)).to be_instance_of(Array)
      a = Importer::CSV.split(brazilmap)
      expect(a[1][2][3]).to eql("Rio Xixé")
    end
  end

end
