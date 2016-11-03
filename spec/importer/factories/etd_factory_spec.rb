require 'rails_helper'
require 'importer'

describe Importer::Factory::ETDFactory do
  let(:factory) { described_class.new(attributes, files) }
  let(:collection_attrs) { { accession_number: ['etds'], title: ['test collection'] } }
  let(:files) { {} }

  let(:attributes) do
    {
      id: 'f3gt5k61',
      title: ['Test Thesis'],
      collection: collection_attrs.slice(:accession_number), files: files,
      created_attributes: [{ start: [2014] }],
      system_number: ['123'],
      author: ['Valerie'],
      identifier: ['ark:/48907/f3gt5k61']
    }.with_indifferent_access
  end

  before do
    ETD.find('f3gt5k61').destroy(eradicate: true) if ETD.exists? 'f3gt5k61'

    # The destroy ^up there^ is not removing the ETD from the collection.
    Collection.destroy_all

    allow($stdout).to receive(:puts) # squelch output
    AdminPolicy.ensure_admin_policy_exists

    # Don't fetch external records during specs
    allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external)
  end

  context 'when a collection already exists' do
    let!(:coll) { Collection.create!(collection_attrs) }

    it 'should not create a new collection' do
      expect(coll.members.size).to eq 0
      obj = nil
      VCR.use_cassette('etd_importer') do
        expect do
          obj = factory.run
        end.to change { Collection.count }.by(0)
      end
      expect(coll.reload.members.size).to eq 1
      expect(coll.members.first).to be_instance_of ETD
      expect(obj.id).to eq 'f3gt5k61'
      expect(obj.system_number).to eq ['123']
      expect(obj.identifier).to eq ['ark:/48907/f3gt5k61']
      expect(obj.author).to eq ['Valerie']
    end
  end

  describe '#create_attributes' do
    subject { factory.create_attributes }

    it 'adds the default attributes' do
      expect(subject[:admin_policy_id]).to eq AdminPolicy::RESTRICTED_POLICY_ID
      expect(subject[:copyright_status]).to eq [RDF::URI('http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr')]
      expect(subject[:license]).to eq [RDF::URI('http://rightsstatements.org/vocab/InC/1.0/')]
    end
  end

  describe 'attach_files' do
    ETD.find('f3gt5k61').destroy(eradicate: true) if ETD.exists? 'f3gt5k61'

    let(:files) do
      {
        xml: 'spec/fixtures/proquest/Button_ucsb_0035D_11990_DATA.xml',
        pdf: 'spec/fixtures/pdf/sample.pdf',
        supplements: [],
      }
    end
    let(:attributes) do
      {
        files: files,
        id: 'f3gt5k61',
        identifier: ['ark:/48907/f3gt5k61'],
        title: ['plunk!'],
      }
    end

    context 'when a PDF is provided' do
      it 'attaches files' do
        VCR.use_cassette('etd_importer') do
          factory.run
        end
        expect(ETD.find('f3gt5k61').file_sets.first.files.first.file_name).to eq(['sample.pdf'])
      end
    end

    context 'when the file is already attached' do
      let!(:etd) do
        VCR.use_cassette('etd_importer') do
          factory.run
        end
      end

      before do
        # The code that checks if the file already exists
        # depends on the file_name, but the file_name gets set
        # by the ingest background job.  For the spec, we'll
        # set the file_name manually.
        fs = etd.file_sets.first
        fs.files.first.file_name = ['sample.pdf']
        fs.save!
      end

      it 'doesn\'t attach the same file again' do
        expect(etd.file_sets.count).to eq 1
        factory.attach_files(etd, files)
        expect(etd.file_sets.count).to eq 1
      end
    end
  end

  describe 'update an existing record' do
    let!(:coll) { Collection.create!(collection_attrs) }
    let(:old_date) { 2222 }
    let(:old_date_attrs) { { created_attributes: [{ start: [old_date] }] }.with_indifferent_access }

    context "when the created date hasn't changed" do
      let!(:etd) { create(:etd, attributes.except(:collection, :files)) }

      it "doesn't add a new duplicate date" do
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]

        factory.run
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context 'when the created date has changed' do
      let!(:etd) { create(:etd, attributes.except(:collection, :files).merge(old_date_attrs)) }

      it 'updates the existing date instead of adding a new one' do
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [old_date]

        factory.run
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the ETD doesn't have existing created date" do
      let!(:etd) { create(:etd, attributes.except(:collection, :files, :created_attributes)) }

      it 'adds the new date' do
        etd.reload
        expect(etd.created).to eq []

        factory.run
        etd.reload
        expect(etd.created.flat_map(&:start)).to eq [2014]
      end
    end

    context "when the ETD has existing created date, but new attributes don't have a date" do
      let(:attributes) do
        { id: 'f3gt5k61',
          system_number: ['123'],
          identifier: ['ark:/48907/f3gt5k61'],
          collection: collection_attrs.slice(:accession_number),
        }.with_indifferent_access
      end

      let!(:etd) { create(:etd, attributes.except(:collection).merge(old_date_attrs)) }

      it "doesn't change the existing date" do
        etd.reload
        expect(etd.created.first.start).to eq [old_date]

        factory.run
        etd.reload
        expect(etd.created.first.start).to eq [old_date]
      end
    end
  end # update an existing record
end
