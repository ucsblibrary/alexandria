require 'rails_helper'
require 'importer'
require 'importer/mods_parser'

describe Importer::ModsImporter do
  def stub_out_indexer
    # Stub out the fetch to avoid calls to external services
    allow_any_instance_of(ActiveTriples::Resource).to receive(:fetch) { 'stubbed' }
  end

  let(:image_directory) { 'spec/fixtures/images' }
  let(:importer) { Importer::ModsImporter.new(image_directory) }

  before do
    allow($stdout).to receive(:puts) # squelch output
    stub_out_indexer
  end

  describe '#import an Image' do
    before do
      Collection.destroy_all
      if ActiveFedora::Base.exists? 'fk/41/23/45/fk41234567'
        ActiveFedora::Base.find('fk/41/23/45/fk41234567').destroy(eradicate: true)
      end
      if ActiveFedora::Base.exists? 'fk/49/87/65/fk49876543'
        ActiveFedora::Base.find('fk/49/87/65/fk49876543').destroy(eradicate: true)
      end
    end
    let(:file) { 'spec/fixtures/mods/cusbspcmss36_110108.xml' }

    let(:identifier1) { double('ARK1', id: 'ark:/99999/fk41234567') }
    let(:identifier2) { double('ARK2', id: 'ark:/99999/fk49876543') }

    it 'creates a new image, files, and a collection' do
      image = nil
      expect(identifier1).to receive(:target=).with(/http:\/\/test\.host\/lib\/ark:\/99999\/fk41234567$/)
      expect(identifier2).to receive(:target=).with(/http:\/\/test\.host\/lib\/ark:\/99999\/fk49876543$/)
      expect(identifier1).to receive(:save)
      expect(identifier2).to receive(:save)
      expect_any_instance_of(Importer::Factory::ImageFactory).to receive(:mint_ark).and_return(identifier1)
      expect_any_instance_of(Importer::Factory::CollectionFactory).to receive(:mint_ark).and_return(identifier2)

      expect do
        image = importer.import(file)
      end.to change { Image.count }.by(1)
        .and change { FileSet.count }.by(2)
        .and change { Collection.count }.by(1)

      original = image.file_sets.first.original_file
      expect(original.mime_type).to eq 'image/tiff'
      expect(original.original_name).to eq 'cusbspcmss36_110108_1_a.tif'

      # Image.reload doesn't clear @file_association
      reloaded = Image.find(image.id)
      expect(reloaded.file_sets.first).not_to be_nil

      expect(reloaded.identifier.first).to match /^ark:\/99999\/fk4\w{7}$/

      expect(reloaded.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

      coll = reloaded.in_collections.first
      expect(coll.accession_number).to eq ['SBHC Mss 36']
      expect(coll.title).to eq 'Santa Barbara picture postcards collection'
      expect(coll.members).to eq [reloaded]
      expect(coll.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

      solr_doc = ActiveFedora::SolrService.query("id:#{image.id}").first
      expect(solr_doc['collection_label_ssim']).to eq ['Santa Barbara picture postcards collection']
    end

    context 'when the collection already exists' do
      before do
        # This ID comes from the ezid VCR cassette:
        if ActiveFedora::Base.exists? 'fk/4c/25/2k/fk4c252k0f'
          ActiveFedora::Base.find('fk/4c/25/2k/fk4c252k0f').destroy(eradicate: true)
        end
        Collection.destroy_all

        # skip creating files
        allow_any_instance_of(Importer::Factory::ImageFactory).to receive(:after_create)
      end
      let!(:coll) { Collection.create(accession_number: ['SBHC Mss 36']) }

      it 'it adds image to existing collection' do
        expect(coll.members.size).to eq 0

        expect do
          VCR.use_cassette('ezid') do
            importer.import(file)
          end
        end.to change { Collection.count }.by(0)

        expect(coll.reload.members.size).to eq 1
      end
    end
  end

  describe '#import a Collection' do
    before do
      # This ID comes from the ezid VCR cassette:
      if ActiveFedora::Base.exists? 'fk/4c/25/2k/fk4c252k0f'
        ActiveFedora::Base.find('fk/4c/25/2k/fk4c252k0f').destroy(eradicate: true)
      end
      Collection.destroy_all
    end
    let(:file) { 'spec/fixtures/mods/sbhcmss78_FlyingAStudios_collection.xml' }

    it 'creates a collection' do
      coll = nil
      expect do
        VCR.use_cassette('ezid') do
          coll = importer.import(file)
        end
      end.to change { Collection.count }.by(1).and change {
        Person.count
      }.by(1)

      expect(coll.id).to match /^fk\/4\w\/\w{2}\/\w{2}\/fk4\w{7}$/
      expect(coll.accession_number).to eq ['SBHC Mss 78']
      expect(coll.title).to eq 'Joel Conway / Flying A Studio photograph collection'
      expect(coll.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

      expect(coll.collector.count).to eq 1
      uri = coll.collector.first.rdf_subject.value
      collector = Person.find(Person.uri_to_id(uri))
      expect(collector.foaf_name).to eq 'Conway, Joel'
    end

    context 'when the collection already exists' do
      let!(:existing) { Collection.create(accession_number: ['SBHC Mss 78']) }

      it 'it adds metadata to existing collection' do
        coll = nil
        expect do
          coll = importer.import(file)
        end.to change { Collection.count }.by(0)

        expect(coll.id).to eq existing.id
        expect(coll.accession_number).to eq ['SBHC Mss 78']
        expect(coll.title).to eq 'Joel Conway / Flying A Studio photograph collection'
      end
    end

    context 'when the person already exists' do
      before do
        # This ID comes from the ezid VCR cassette:
        if ActiveFedora::Base.exists? 'fk/4c/25/2k/fk4c252k0f'
          ActiveFedora::Base.find('fk/4c/25/2k/fk4c252k0f').destroy(eradicate: true)
        end
        Person.destroy_all
      end
      let!(:existing) { Person.create(foaf_name: 'Conway, Joel') }

      it "doesn't create another person" do
        coll = nil
        expect do
          VCR.use_cassette('ezid') do
            coll = importer.import(file)
          end
        end.to change { Collection.count }.by(1).and change {
          Person.count
        }.by(0)

        expect(coll.collector.count).to eq 1
        uri = coll.collector.first.rdf_subject.value
        collector = Person.find(Person.uri_to_id(uri))
        expect(collector.id).to eq existing.id
      end
    end
  end

  describe 'fields that have Strings instead of URIs' do
    let(:file) { 'spec/fixtures/mods/sbhcmss78_FlyingAStudios_collection.xml' }

    let(:frodo) { 'Frodo Baggins' }
    let(:bilbo) { 'Bilbo Baggins' }
    let(:pippin) { RDF::URI.new('http://id.loc.gov/authorities/names/pippin') }

    context 'when rights_holder has strings or uris' do
      before do
        # This ID comes from the ezid VCR cassette:
        if ActiveFedora::Base.exists? 'fk/4c/25/2k/fk4c252k0f'
          ActiveFedora::Base.find('fk/4c/25/2k/fk4c252k0f').destroy(eradicate: true)
        end
        Agent.delete_all
        Agent.create(foaf_name: frodo) # existing rights holder
        allow_any_instance_of(Importer::ModsParser).to receive(:rights_holder) { [frodo, bilbo, pippin] }
      end

      it 'finds or creates the rights holders' do
        expect do
          VCR.use_cassette('ezid') do
            coll = importer.import(file)
          end
        end.to change { Agent.exact_model.count }.by(1)

        rights_holders = Agent.exact_model
        expect(rights_holders.map(&:foaf_name).sort).to eq [bilbo, frodo]
      end
    end
  end
end
