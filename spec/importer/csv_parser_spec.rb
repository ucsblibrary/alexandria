require 'rails_helper'
require 'importer'

describe Importer::CSVParser do
  let(:parser) { described_class.new(file) }
  let(:attributes) { parser.attributes }
  let(:file) { 'spec/fixtures/csv/pamss045.csv' }
  let(:first_record) { parser.first }

  context 'Importing just images' do
    it 'parses a record' do
      # Title must be singular
      expect(first_record[:title]).to eq ['Dirge for violin and piano (violin part)']

      expect(first_record[:files]).to eq ['dirge1.tif', 'dirge2.tif', 'dirge3.tif', 'dirge4.tif']

      expect(first_record[:copyright_status]).to eq [RDF::URI('http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr')]

      expect(first_record[:collection]).to eq(id: 'pasmss45', title: ['Mildred Couper papers'], accession_number: ['PA Mss 45'])

      expect(first_record[:created_attributes]).to eq [{ start: ['1937'] }]
      expect(first_record[:composer]).to eq [RDF::URI('http://id.loc.gov/authorities/names/no93011759')]

      expect(first_record.keys).to match_array [:accession_number, :citation, :collection, :composer, :copyright_status, :description_standard, :digital_origin, :extent, :files, :form_of_work, :institution, :language, :lc_subject, :license, :rights_holder, :series_name, :sub_location, :title, :restrictions, :work_type, :created_attributes]
    end
  end

  context 'Importing images and collections' do
    let(:file) { 'spec/fixtures/csv/pamss045_with_type.csv' }
    let(:collection_record) { parser.to_a.last }

    it 'parses a records' do
      expect(first_record[:type]).to eq 'Image'
      expect(collection_record[:type]).to eq 'Collection'

      # Title must be singular
      expect(first_record[:title]).to eq ['Dirge for violin and piano (violin part)']

      expect(collection_record[:finding_aid]).to eq ['Third shelf on the right']
    end
  end

  describe 'parsing local authorities' do
    let(:file) { 'spec/fixtures/csv/pamss045_with_local_authorities.csv' }

    let(:composer_uri) { RDF::URI('http://id.loc.gov/authorities/names/no93011759') }
    let(:composer_person) do
      { type: 'Person',
        name: 'J. Anderson' }
    end
    let(:composer_group) do
      { type: 'Group',
        name: 'Anderson Choir' }
    end
    let(:micro_music) { RDF::URI('http://id.loc.gov/authorities/subjects/sh85084939') }
    let(:women_comp) { RDF::URI('http://id.loc.gov/authorities/subjects/sh85147508') }
    let(:jefrey) { { type: 'Person', name: 'Jefrey' } }
    let(:jef_topic)  { { type: 'Topic', name: "Jef's Topic" } }

    it 'captures the types to pass on to the importer' do
      expect(first_record[:composer]).to eq [composer_uri, composer_person, composer_group]
      expect(first_record[:lc_subject]).to eq [micro_music, jef_topic, jefrey, women_comp]
    end

    # Make sure we haven't broken the work_type attribute by
    # adding the *_type pattern matching to the parser.
    it 'correctly finds work_type' do
      expect(first_record[:work_type]).to eq ['http://id.loc.gov/vocabulary/resourceTypes/not']
    end
  end

  describe 'validating CSV headers' do
    subject { parser.send(:validate_headers, headers) }

    context 'with valid headers' do
      let(:headers) { %w(accession_number title) }
      it { is_expected.to eq headers }
    end

    context 'with invalid headers' do
      let(:headers) { ['something bad', 'title'] }

      it 'raises an error' do
        expect { subject }.to raise_error 'Invalid headers: something bad'
      end
    end

    context 'with "*_type" fields for local authorities' do
      let(:headers) { %w(rights_holder rights_holder_type rights_holder title) }
      it { is_expected.to eq headers }
    end

    # The CSV parser assumes that the *_type column comes just
    # before the column that contains the value for that local
    # authority.  If the columns aren't in the correct order,
    # raise an error.
    context 'with columns in the wrong order' do
      let(:headers) { %w(rights_holder_type rights_holder_type rights_holder title) }

      it 'raises an error' do
        expect { subject }.to raise_error "Invalid headers: 'rights_holder_type' column must be immediately followed by 'rights_holder' column."
      end
    end

    context 'with nil headers' do
      let(:headers) { ['title', nil] }
      it { is_expected.to eq headers }
    end

    # It doesn't expect a matching column for "work_type"
    context 'with work_type column' do
      let(:headers) { %w(work_type rights_holder title) }
      it { is_expected.to eq headers }
    end

    # note_type is handled separately
    context 'with note_type column' do
      let(:headers) { %w(note_type note_value title) }
      it { is_expected.to eq headers }
    end
  end
end
