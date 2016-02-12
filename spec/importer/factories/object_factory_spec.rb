require 'rails_helper'
require 'importer'

describe Importer::Factory::ObjectFactory do
  before { AdminPolicy.ensure_admin_policy_exists }

  subject { Importer::Factory::CollectionFactory.new(attributes, './tmp') }

  let(:afmc) { 'http://id.loc.gov/authorities/names/n87914041' }
  let(:afmc_uri) { RDF::URI.new(afmc) }

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
end
