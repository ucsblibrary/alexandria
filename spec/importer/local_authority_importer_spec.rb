require 'rails_helper'
require 'importer'

describe Importer::LocalAuthorityImporter do
  let(:importer) { described_class.new(input_file) }
  let(:input_file) { File.join(fixture_path, 'local_authority_csv', 'authorities.csv') }

  before do
    # Don't print exporter status messages while running tests
    allow($stdout).to receive(:puts)
  end

  it 'takes a CSV input file' do
    expect(importer.input_file).to eq input_file
  end

  describe '#run (create new records)' do
    # These are the objects we expect to create
    let(:mark) {{ id: 'agent-1', name: 'Mark', model: Agent }}
    let(:justin) {{ id: 'person-1', name: 'Justin', model: Person }}
    let(:alicia) {{ id: 'person-2', name: 'Alicia', model: Person }}
    let(:devs) {{ id: 'group-1', name: 'DCE Dev Team', model: Group }}
    let(:dce) {{ id: 'org-1', name: 'DCE', model: Organization }}
    let(:tools) {{ id: 'topic-1', model: Topic,
                   name: ['hydra', 'blacklight', 'fedora', 'solr'] }}
    let(:fun) {{ id: 'topic-2', model: Topic,
                 name: ['happy hour', 'nerdy jokes'] }}

    before { AdminPolicy.ensure_admin_policy_exists }

    it 'imports the local authorities' do
      expect { importer.run }
        .to change { Agent.exact_model.count }.by(1)
        .and change { Person.count }.by(2)
        .and change { Group.count }.by(1)
        .and change { Organization.count }.by(1)
        .and change { Topic.count }.by(2)

      object = Person.find(justin[:id])
      expect(object.foaf_name).to eq justin[:name]
      expect(object.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID

      object = Topic.find(tools[:id])
      expect(object.label).to eq tools[:name]
      expect(object.admin_policy_id).to eq AdminPolicy::PUBLIC_POLICY_ID
    end
  end  # run (create new records)


  describe '#run (update existing record)' do
    let(:input_file) { File.join(fixture_path, 'local_authority_csv', 'justin.csv') }
    let(:justin) {{ id: 'person-1', name: 'Justin' }}
    let(:old_name) { 'Old name should get replaced' }

    before do
      AdminPolicy.ensure_admin_policy_exists
      if ActiveFedora::Base.exists?(justin[:id])
        ActiveFedora::Base.find(justin[:id]).destroy(eradicate: true)
      end
      Person.create(id: justin[:id], foaf_name: old_name)
    end

    it 'updates the local authorities' do
      expect { importer.run }
        .to change { Person.count }.by(0)
      object = Person.find(justin[:id])
      expect(object.foaf_name).to eq justin[:name]
    end
  end  # run (update existing record)


  describe '#model' do
    context 'when the model name is lowercase' do
      subject { importer.model(attrs) }
      let(:attrs) {{ type: 'person' }}
      it { is_expected.to eq Person }
    end

    context 'when the model name is blank' do
      let(:attrs) {{ type: '' }}

      it 'raises an error' do
        expect { importer.model(attrs) }.to raise_error '"type" column cannot be blank'
      end
    end
  end

end
