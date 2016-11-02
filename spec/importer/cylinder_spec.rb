# coding: utf-8
require 'rails_helper'
require 'importer'

describe Importer::Cylinder do
  let(:files_dir) { File.join(fixture_path, 'cylinders2') }
  let(:meta_files) do # Records are spread across 2 files
    [File.join(fixture_path, 'marcxml', 'cylinder_sample_marc.xml'),
     File.join(files_dir, 'cylinders_2.xml')]
  end
  let(:options) { {} }
  let(:importer) { described_class.new(meta_files, files_dir, options) }

  # Give it an identifier so it doesn't try to mint a new ark
  # during the specs.  Also needs a title to be a valid record.
  let(:collection_attrs) {{ identifier: ['some_ark'], title: ['Cylinders Collection'] }}
  let(:collection) { Importer::Factory::CollectionFactory.new(Importer::Cylinder::COLLECTION_ATTRIBUTES.merge(collection_attrs)).find_or_create }

  before do
    # Don't run background jobs/derivatives during the specs
    allow(CharacterizeJob).to receive_messages(perform_later: nil, perform_now: nil)

    # Don't print output messages during specs
    allow($stdout).to receive(:puts)

    # Don't fetch external records during specs
    allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external)
  end

  describe '#attributes' do
    before { collection } # Make sure collection exists

    let(:meta_files) { [File.join(fixture_path, 'marcxml', 'cylinder_sample_marc.xml')] }

    let(:marc_record) do
      records = importer.parse_marc_files(meta_files)
      records.first
    end

    let(:indexer) { importer.indexer }

    subject { importer.attributes(marc_record, indexer) }

    it 'parses the attributs from the MARC file' do
      expect(subject['marc_subjects']).to contain_exactly(
        'Music -- French Polynesia -- Tahiti (Island)',
        'Presidents -- United States -- Election -- 1908',
        'Spanish language -- Study and teaching -- Sound recordings',
        'United States -- History -- Civil War, 1861-1865 -- Songs and music',
        'United States -- Boundaries -- Canada'
      )
      expect(subject['accession_number']).to eq ['Cylinder 4373', 'Cylinder 4374', 'Cylinder 4377']
      expect(subject['edition']).to eq ['[Pathé Stentor (Concert) ed.]']
      expect(subject['description']).to eq ['Baritone solo with orchestra accompaniment.\nIt\'s really good and you should all listen.']
      expect(subject['extent']).to eq ['1 cylinder (ca. 2 min.) : 160 rpm ; 2 1/4 x 4 in. 1 record slip']
      expect(subject['form_of_work']).to eq ['Musical settings', 'Sound recordings', 'Songs and music', 'Humorous monologues']
      expect(subject['fulltext_link']).to(
        contain_exactly('http://www.library.ucsb.edu/OBJID/Cylinder4373',
                        'http://www.library.ucsb.edu/OBJID/Cylinder4374',
                        'http://www.library.ucsb.edu/OBJID/Cylinder4377')
      )
      expect(subject['issue_number']).to eq []
      expect(subject['lc_subject']).to(
        contain_exactly({ type: 'person', name: 'Burns, Robert, 1759-1796' },
                        { type: 'organization', name: 'Loyal Order of Moose' },
                        { type: 'topic', name: 'Humoresques' },
                        { type: 'topic', name: 'Music' },
                        { type: 'topic', name: 'Presidents' },
                        { type: 'topic', name: 'Election' },
                        { type: 'topic', name: '1908' },
                        { type: 'topic', name: 'Spanish language' },
                        { type: 'topic', name: 'Study and teaching' },
                        { type: 'topic', name: 'History' },
                        { type: 'topic', name: 'Civil War, 1861-1865' },
                        { type: 'topic', name: 'Boundaries' })
      )
      expect(subject['location']).to(
        contain_exactly('United States',
                        'French Polynesia',
                        'Tahiti (Island)',
                        'United States Canada')
      )
      expect(subject['note']).to eq ['Edison Gold Moulded Record: 8525.',
                                     'Year of release and descriptor from "The Edison Phonograph Monthly," v.1 (1903/1904).',
                                     '"Coon song."',
                                     'Copies 2, 3 are possible alternate takes.',
                                     { type: :performer, name: 'Arthur Collins.' },
                                     { type: :venue, name: 'Issue number from "Edison Cylinder Records, 1889-1912" / Koenigsberg, c1969.' },
                                     { type: :ownership, name: 'Todd collection.' }]
      expect(subject['publisher']).to eq ['Edison Gold Moulded Record']
      expect(subject['place_of_publication']).to eq ['Orange, N.J.']
      expect(subject['table_of_contents']).to eq ["The whistling coon Sam Devere, words / Sam Raeburn, music -- sleep, baby, sleep -- if it wasn't for the irish and the jews William Jerome, words / Jean Schwartz, music"]
    end
  end # attributes

  describe 'when the collection doesn\'t exist' do
    before { Collection.destroy_all }

    it 'raises an exception' do
      expect { importer.run }.to raise_error(CollectionNotFound, 'Not Found: Collection with accession number ["Cylinders"]')
      expect(importer.imported_records_count).to eq 0
    end
  end

  # The full import process, from start to finish
  describe 'import records from MARC files' do
    before do
      Organization.destroy_all
      Person.destroy_all
      Group.destroy_all
      FileSet.destroy_all
      AudioRecording.all.map(&:id).each do |id|
        ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
      end
      collection # Make sure collection exists
    end

    it 'imports the records' do
      expect do
        VCR.use_cassette('cylinder_import') do
          importer.run
        end
      end.to change { AudioRecording.count }.by(3)
        .and(change { FileSet.count }.by(2))

      # Make sure the importer reports the correct number
      expect(importer.imported_records_count).to eq 3

      # The new cylinder records
      record1 = AudioRecording.where(Solrizer.solr_name('system_number', :symbol) => '002556253').first
      record2 = AudioRecording.where(Solrizer.solr_name('system_number', :symbol) => '002145837').first
      record3 = AudioRecording.where(Solrizer.solr_name('system_number', :symbol) => '002145838').first

      # Check the attached files.
      # Both record1 and record3 have cylinder files listed in
      # the MARC file, but there are no files with that name
      # in the files_dir, so no files will get attached for
      # thise spec.
      expect(record1.file_sets).to eq []
      expect(record2.file_sets.map(&:title).flatten).to contain_exactly('Cylinder0006', 'Cylinder12783')
      expect(record3.file_sets).to eq []

      # Check the titles
      expect(record1.title).to eq ['Any rags']
      expect(record1.alternative).to eq ['Le réve.']
      expect(record2.title).to eq ['In the shade of the old apple tree']
      expect(record3.title).to eq ['Pagliacci. Vesti la giubba']

      # Check the metadata for record1
      expect(record1.accession_number).to contain_exactly('Cylinder 4373', 'Cylinder 4374', 'Cylinder 4377')
      expect(record1.copyright_status.map(&:class)).to eq [Oargun::ControlledVocabularies::CopyrightStatus]
      expect(record1.digital_origin).to eq ['reformatted digital']
      expect(record1.edition).to eq ['[Pathé Stentor (Concert) ed.]']
      expect(record1.institution.map(&:class)).to eq [Oargun::ControlledVocabularies::Organization]
      expect(record1.issued.first.label).to eq ['[1903]']
      expect(record1.issued.first.to_a).to eq 1903
      expect(record1.language.first.rdf_subject).to eq RDF::URI('http://id.loc.gov/vocabulary/iso639-2/eng')
      expect(record1.lc_subject.count).to eq 12
      expect(record1.lc_subject.first.class).to eq Oargun::ControlledVocabularies::Subject
      record1.lc_subject.map(&:solrize).flatten.each do |uri|
        expect(uri).to(
          match(%r{(http://test.host/authorities/topics/.{8}-.{4}-.{4}-.{4}-.{12})|(http://test.host/authorities/people/.{8}-.{4}-.{4}-.{4}-.{12})|(http://test.host/authorities/organizations/.{8}-.{4}-.{4}-.{4}-.{12})})
        )
      end
      expect(record1.license.map(&:class)).to eq [Oargun::ControlledVocabularies::RightsStatement]
      expect(record1.location.first.class).to eq Oargun::ControlledVocabularies::Geographic
      expect(record1.matrix_number).to eq []
      expect(record1.description).to eq ['Baritone solo with orchestra accompaniment.\nIt\'s really good and you should all listen.']
      expect(record1.extent).to eq ['1 cylinder (ca. 2 min.) : 160 rpm ; 2 1/4 x 4 in. 1 record slip']
      expect(record1.form_of_work).to contain_exactly('Humorous monologues', 'Musical settings', 'Songs and music', 'Sound recordings')
      expect(record1.fulltext_link).to(
        contain_exactly('http://www.library.ucsb.edu/OBJID/Cylinder4373',
                        'http://www.library.ucsb.edu/OBJID/Cylinder4374',
                        'http://www.library.ucsb.edu/OBJID/Cylinder4377')
      )
      expect(record1.notes.map(&:value)).to(
        contain_exactly(
          ['Arthur Collins.'],
          ['"Coon song."'],
          ['Copies 2, 3 are possible alternate takes.'],
          ['Edison Gold Moulded Record: 8525.'],
          ['Issue number from "Edison Cylinder Records, 1889-1912" / Koenigsberg, c1969.'],
          ['Todd collection.'],
          ['Year of release and descriptor from "The Edison Phonograph Monthly," v.1 (1903/1904).']
        )
      )
      expect(record1.publisher).to eq ['Edison Gold Moulded Record']
      expect(record1.place_of_publication).to eq ['Orange, N.J.']
      expect(record1.sub_location).to eq ['Department of Special Research Collections']
      expect(record1.table_of_contents).to eq ["The whistling coon Sam Devere, words / Sam Raeburn, music -- sleep, baby, sleep -- if it wasn't for the irish and the jews William Jerome, words / Jean Schwartz, music"]

      # Check the contributors are correct
      [:performer,
       :instrumentalist,
       :lyricist,
       :arranger,
       :rights_holder,
       :singer].each do |property_name|
        contributor = record1.send(property_name)
        expect(contributor.map(&:class).uniq).to eq [Oargun::ControlledVocabularies::Creator]
      end

      # Check local authorities were created for performers
      ids = record1.performer.map { |s| s.rdf_label.first.gsub(%r{^.*\/}, '') }
      perfs = ids.map { |id| ActiveFedora::Base.find(id) }
      org = perfs.find { |target| target.is_a? Organization }
      group = perfs.find { |target| target.is_a? Group }
      person = perfs.find { |target| target.is_a? Person }

      expect(org.foaf_name).to eq 'United States. National Guard Bureau. Fife and Drum Corps.'
      expect(group.foaf_name).to eq 'Allen field c text 1876 field q text'
      expect(person.foaf_name).to eq 'Milner, David,'

      # Check local authorities were created for singers
      ids = record1.singer.map { |s| s.rdf_label.first.gsub(Regexp.new('^.*\/'), '') }
      singers = ids.map { |id| ActiveFedora::Base.find(id) }
      org, person = singers.partition { |obj| obj.is_a?(Organization) }.map(&:first)
      expect(org.foaf_name).to eq 'Louisiana Five. text from b.'
      expect(person.foaf_name).to eq 'Collins, Arthur.'
      expect(person.class).to eq Person

      # This is the same person who is listed as 3 different
      # types of contributor.
      person_id = record1.instrumentalist.first.rdf_label.first.gsub(Regexp.new('^.*\/'), '')
      person = Person.find(person_id)
      expect(person.foaf_name).to eq 'Allen, Thos. S., 1876-1919.'
      [:instrumentalist, :lyricist, :arranger].each do |property_name|
        contributor = record1.send(property_name)
        contributor_id = contributor.first.rdf_label.first.gsub(Regexp.new('^.*\/'), '')
        expect(contributor_id).to eq person.id
      end

      # Check the collection membership
      expect(record1.local_collection_id).to eq [collection.id]

      # Check collection membership is properly indexed in solr
      solr = Blacklight.default_index.connection
      res = solr.select(params: { id: collection.id, qt: 'document' })
      doc = res['response']['docs'].first
      expect(doc['member_ids_ssim']).to contain_exactly(record1.id, record2.id, record3.id)
    end
  end

  context 'a record without an ARK' do
    let(:files_dir) { File.join(fixture_path, 'marcxml') }
    let(:meta_files) { [File.join(files_dir, 'cylinder_missing_ark.xml')] }

    before do
      AudioRecording.all.map(&:id).each do |id|
        ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
      end
    end

    it 'skips that record, but imports other records' do
      expect do
        importer.run
      end.to change { AudioRecording.count }.by(1)
      expect(importer.imported_records_count).to eq 1
    end
  end

  context 'marc file without language' do
    let(:files_dir) { File.join(fixture_path, 'marcxml') }
    let(:meta_files) { [File.join(files_dir, 'cylinder_sample_without_language_marc.xml')] }
    let(:id) { 'f3888888' } # ID from the MARC file

    before do
      ActiveFedora::Base.find(id).destroy(eradicate: true) if ActiveFedora::Base.exists?(id)
    end

    it 'creates the audio record' do
      expect do
        importer.run
      end.to change { AudioRecording.count }.by(1)

      audio = AudioRecording.find(id)
      expect(audio.language).to eq []
    end
  end
end
