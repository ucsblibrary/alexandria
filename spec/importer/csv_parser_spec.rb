require 'rails_helper'
require 'importer'

describe Importer::CSVParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }
  let(:file) { 'spec/fixtures/csv/pamss045.csv' }

  let(:first_record) { parser.first }

  it 'parses a record' do
    # Title must be singular
    expect(first_record[:title]).to eq 'Dirge for violin and piano (violin part)'

    expect(first_record[:files]).to eq ['dirge1.tif', 'dirge2.tif', 'dirge3.tif', 'dirge4.tif']

    expect(first_record[:copyright_status]).to eq [RDF::URI('http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr')]

    expect(first_record[:collection]).to eq(id: 'pasmss45', title: 'Mildred Couper papers', accession_number: ['PA Mss 45'])

    expect(first_record[:created_attributes]).to eq [{ start: ['1937'] }]
    expect(first_record[:composer]).to eq [RDF::URI('http://id.loc.gov/authorities/names/no93011759')]

    expect(first_record.keys).to match_array [:accession_number, :citation, :collection, :composer, :copyright_status, :description_standard, :digital_origin, :extent, :files, :form_of_work, :institution, :language, :lc_subject, :license, :rights_holder, :series_name, :sub_location, :title, :use_restrictions, :work_type, :created_attributes]
  end
end
