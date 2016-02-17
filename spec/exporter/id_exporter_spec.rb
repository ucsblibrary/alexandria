require 'rails_helper'
require 'exporter/id_exporter'

describe Exporter::IdExporter do
  let(:dir) { File.join('tmp', 'test_exports') }
  let(:file) { 'test_id_export.csv' }

  let(:exporter) { described_class.new(dir, file) }

  before do
    # Don't print exporter status messages while running tests
    allow($stdout).to receive(:puts)
  end

  it 'takes an output directory and filename' do
    expect(exporter.export_dir).to eq dir
    expect(exporter.export_file_name).to eq file
    expect(exporter.export_file).to eq File.join(dir, file)
  end

  describe '#run' do
    before do
      [Image, ETD, Collection].each { |model| model.destroy_all }
      AdminPolicy.ensure_admin_policy_exists
    end

    after { FileUtils.rm_rf(dir, secure: true) }

    # Create some records to export
    let!(:animals) { create(:collection,
                            title: ['My Favorite Animals'],
                            identifier: ['ark:/123/animals'],
                            accession_number: ['animals_123']) }
    let!(:puppies) { create(:image, title: ['Puppies'],
                            identifier: ['ark:/123/puppies'],
                            accession_number: ['puppies_123']) }
    let!(:kitties) { create(:image, title: ['Kitties'],
                            identifier: ['ark:/123/kitties'],
                            accession_number: ['kitties_123']) }
    let!(:etd) { ETD.create!(title: ['Cute Animals Thesis'],
                             identifier: ['ark:/123/thesis'],
                             accession_number: ['thesis_123']) }

    let(:headers) { %w(type fedora_id accession_number ark title) }

    it 'exports the records' do
      exporter.run

      export_file = File.join(dir, file)
      contents = File.readlines(export_file).map(&:strip)

      # The file should have 5 lines total
      expect(contents.count).to eq 5

      expect(contents[0].split(',')).to eq headers

      expect(contents[1].split(',')).to eq ['Collection', animals.id, animals.accession_number.first, animals.ark, animals.title.first]

      line2 = contents[2].split(',')
      line3 = contents[3].split(',')

      # We don't know what order they will be in.  Decide if
      # we should compare this line to 'puppies' or 'kitties'.
      image = line2[1] == puppies.id ? puppies : kitties
      expect(line2).to eq ['Image', image.id, image.accession_number.first, image.ark, image.title.first]

      image = line3[1] == puppies.id ? puppies : kitties
      expect(line3).to eq ['Image', image.id, image.accession_number.first, image.ark, image.title.first]

      expect(contents[4].split(',')).to eq ['ETD', etd.id, etd.accession_number.first, etd.ark, etd.title.first]
    end
  end  # run

end
