require 'rails_helper'
require 'importer'

describe Importer::Factory::ObjectFactory do
  before { AdminPolicy.ensure_admin_policy_exists }

  subject { Importer::Factory::CollectionFactory.new(attributes, './tmp') }

  let(:afmc) { 'http://id.loc.gov/authorities/names/n87914041' }
  let(:afmc_uri) { RDF::URI.new(afmc) }

  describe '#find' do
    context 'existing object' do
      let(:importer) { Importer::Factory::ImageFactory.new(attributes, './tmp') }
      subject { importer.find }

      let(:a_num) { ['acc num 1', 'acc num 2'] }
      let(:image_attrs) {{ title: ['Something Title'], accession_number: a_num }}
      let!(:image) { create(:image, image_attrs) }

      context 'with an id' do
        let(:attributes) {{ id: image.id }}

        it 'finds the exisiting object' do
          expect(subject.class).to eq Image
          expect(subject.title).to eq image_attrs[:title]
        end
      end

      context 'with accession_number' do
        let(:attributes) {{ accession_number: [image.accession_number.first] }}

        it 'finds the exisiting object' do
          expect(subject.class).to eq Image
          expect(subject.title).to eq image_attrs[:title]
        end
      end

      context 'with neither id nor accession_number' do
        let(:attributes) {{ accession_number: [] }}

        it 'raises an error' do
          expect { subject }.to raise_error 'Missing identifier: Unable to search for existing object without either fedora ID or accession_number'
        end
      end
    end
  end

  describe '#find_or_create_rights_holders' do
    before { Agent.destroy_all }
    let(:regents_uri) { 'http://id.loc.gov/authorities/names/n85088322' }
    let(:regents_string) { 'Regents of the Univ.' }
    let(:attributes) { { rights_holder: [RDF::URI.new(regents_uri), regents_string] } }

    context "when local rights holder doesn't exist" do
      it 'creates a rights holder' do
        expect(Agent.count).to eq 0
        rh = nil
        expect do
          rh = subject.find_or_create_rights_holders(attributes)
        end.to change { Agent.count }.by(1)
        expect(rh.fetch(:rights_holder).map(&:class).uniq).to eq [RDF::URI]
        local_rights_holder = Agent.first
        expect(local_rights_holder.foaf_name).to eq regents_string
        expect(rh.fetch(:rights_holder)).to eq [regents_uri, local_rights_holder.public_uri]
      end
    end

    context 'when existing local rights holder' do
      let!(:existing_rh) { Agent.create(foaf_name: regents_string) }

      it 'finds the existing rights holder' do
        rh = nil
        expect do
          rh = subject.find_or_create_rights_holders(attributes)
        end.to change { Agent.exact_model.count }.by(0)

        expect(rh.fetch(:rights_holder).map(&:to_s)).to eq [regents_uri, existing_rh.public_uri]
      end
    end

    context 'when similar name' do
      let!(:frodo) { Agent.create(foaf_name: 'Frodo Baggins') }
      let(:attributes) { { rights_holder: ['Bilbo Baggins'] } }

      it 'only finds exact name matches' do
        expect do
          subject.find_or_create_rights_holders(attributes)
        end.to change { Agent.count }.by(1)
        expect(Agent.all.map(&:foaf_name).sort).to eq ['Bilbo Baggins', 'Frodo Baggins']
      end
    end

    context 'when name matches, but model is wrong' do
      let!(:frodo) { Person.create(foaf_name: 'Frodo Baggins') }
      let(:attributes) { { rights_holder: ['Frodo Baggins'] } }

      it 'only matches exact model' do
        expect do
          subject.find_or_create_rights_holders(attributes)
        end.to change { Agent.count }.by(1)
      end
    end

    context 'when the type is specified' do
      let(:attributes) do
        { rights_holder: [{ name: 'Bilbo Baggins',
                            type: 'Person' }] }
      end

      it 'creates the local rights holder' do
        rh = nil
        expect do
          rh = subject.find_or_create_rights_holders(attributes)
        end.to change { Person.count }.by(1)
        expect(rh.fetch(:rights_holder).map(&:class)).to eq [RDF::URI]
      end
    end
  end

  describe '#find_or_create_contributors' do
    let(:fields) { [:creator, :collector, :contributor] }
    let(:joel) { 'Joel Conway' }
    before { Agent.destroy_all }

    # The attributes hash that comes from the ModsParser
    let(:attributes) do
      { creator: [afmc_uri],
        contributor: [afmc_uri, { name: joel, type: 'personal' }] }
    end

    context "when contributors don't exist yet" do
      it 'creates the contributors and returns a hash of the contributors' do
        expect(Person.count).to eq 0
        contributors = nil

        expect do
          contributors = subject.find_or_create_contributors(fields, attributes)
        end.to change { Person.count }.by(1)

        expect(contributors.keys.sort).to eq [:contributor, :creator]
        expect(contributors[:creator].first.class).to eq RDF::URI
        expect(contributors[:creator]).to eq [afmc]
        expect(contributors[:contributor].count).to eq 2
        expect(contributors[:contributor].map(&:class).uniq).to eq [RDF::URI]
        new_person = Person.first
        expect(new_person.foaf_name).to eq joel
        expect(contributors[:contributor]).to include new_person.public_uri
        expect(contributors[:contributor]).to include afmc
      end
    end

    context 'when contributors already exist' do
      let!(:person) { Person.create(foaf_name: joel) }

      it 'returns a hash of the contributors' do
        contributors = nil
        expect do
          contributors = subject.find_or_create_contributors(fields, attributes)
        end.to change { Person.count }.by(0)

        expect(contributors.keys.sort).to eq [:contributor, :creator]
        expect(contributors[:creator].first.class).to eq RDF::URI
        expect(contributors[:creator]).to eq [afmc]
        expect(contributors[:contributor].count).to eq 2
        expect(contributors[:contributor].map(&:class).uniq).to eq [RDF::URI]
        expect(contributors[:contributor]).to include afmc
        expect(contributors[:contributor]).to include person.public_uri
      end
    end

    context 'when similar name' do
      let!(:frodo) { Person.create(foaf_name: 'Frodo Baggins') }
      let(:attributes) { { creator: [{ name: 'Bilbo Baggins', type: 'personal' }] } }

      it 'only finds exact name matches' do
        expect do
          subject.find_or_create_contributors([:creator], attributes)
        end.to change { Person.count }.by(1)
        expect(Person.all.map(&:foaf_name).sort).to eq ['Bilbo Baggins', 'Frodo Baggins']
      end
    end

    context 'with class directly given in the type field' do
      # The attributes hash that comes from the CSVParser
      let(:attributes) do
        { creator: [{ name: 'Bilbo Baggins', type: 'Person' }],
          composer: [{ name: 'Frodo', type: 'Group' }] }
      end
      let(:fields) { [:creator, :composer] }

      it 'creates the local authorities' do
        expect do
          subject.find_or_create_contributors(fields, attributes)
        end.to change { Person.count }.by(1)
          .and change { Group.count }.by(1)
      end
    end
  end  # '#find_or_create_contributors'

  describe '#find_or_create_subjects' do
    let(:attributes) do
      { lc_subject: [{ name: 'Bilbo Baggins', type: 'Person' },
                     afmc_uri,
                     { name: 'A Local Subj', type: 'Topic' }] }
    end

    context "local authorities don't exist yet" do
      before do
        Person.delete_all
        Topic.delete_all
      end

      it 'creates the missing local subjects' do
        attrs = nil
        expect do
          attrs = subject.find_or_create_subjects(attributes)
        end.to change { Person.count }.by(1)
          .and change { Topic.count }.by(1)

        bilbo = Person.first
        expect(bilbo.foaf_name).to eq 'Bilbo Baggins'

        subj = Topic.first
        expect(subj.label).to eq ['A Local Subj']

        expect(attrs[:lc_subject]).to eq [bilbo.public_uri, afmc, subj.public_uri]
      end
    end
  end  # find_or_create_subjects

  describe 'update existing image' do
    let(:importer) { Importer::Factory::ImageFactory.new(attributes, './tmp') }
    let(:old_note) {{ note_type: 'old type', value: 'old value' }}
    let(:image) { create(:image, notes_attributes: [old_note]) }

    context 'when there are no new notes (but old notes exist)' do
      let(:attributes) {{ id: image.id, title: ['new title'] }}

      it 'clears out the old notes' do
        expect(image.notes.count).to eq 1
        expect(image.notes[0].note_type).to eq ['old type']
        expect(image.notes[0].value).to eq ['old value']

        importer.run
        reloaded = image.reload

        expect(reloaded.notes.count).to eq 1
        expect(reloaded.notes[0].note_type).to eq ['']
        expect(reloaded.notes[0].value).to eq ['']
      end
    end

    context 'with new notes' do
      let(:attributes) {
        { id: image.id,
          note:  [ 'an untyped note',
                  { type: "type 1", name: "note 1" },
                  { type: "type 2", name: "note 2" }] }
      }

      it 'updates the notes' do
        expect(image.notes.count).to eq 1
        expect(image.notes[0].note_type).to eq ['old type']
        expect(image.notes[0].value).to eq ['old value']

        importer.run
        reloaded = image.reload

        expect(reloaded.notes[0].note_type).to eq ['']
        expect(reloaded.notes[0].value).to eq ['an untyped note']
        expect(reloaded.notes[1].note_type).to eq ['type 1']
        expect(reloaded.notes[1].value).to eq ['note 1']
        expect(reloaded.notes[2].note_type).to eq ['type 2']
        expect(reloaded.notes[2].value).to eq ['note 2']
        expect(reloaded.notes.count).to eq 3
      end
    end
  end

  describe '#transform_attributes' do
    let(:importer) { Importer::Factory::ImageFactory.new(attributes, './tmp') }
    subject { importer.send(:transform_attributes) }

    context 'with notes' do
      let(:attributes) {
        { note:  [ 'an untyped note',
                  { type: "type 1", name: "note 1" },
                  { type: "type 2", name: "note 2" }] }
      }

      it 'parses the notes attributes' do
        expect(subject[:note]).to be_nil
        expect(subject[:notes_attributes][0]).to eq({ note_type: nil, value: 'an untyped note' })
        expect(subject[:notes_attributes][1]).to eq({ note_type: 'type 1', value: 'note 1' })
        expect(subject[:notes_attributes][2]).to eq({ note_type: 'type 2', value: 'note 2' })
      end
    end
  end

end
