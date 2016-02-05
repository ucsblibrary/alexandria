require 'rails_helper'
require 'exporter/local_authority_exporter'

describe Exporter::LocalAuthorityExporter do
  let(:dir) { File.join('tmp', 'test_exports') }
  let(:file) { 'test_export.csv' }

  let(:exporter) { described_class.new(dir, file) }

  before do
    # Don't print exporter status messages while running tests
    allow($stdout).to receive(:puts)
  end

  it 'takes an output directory and filename' do
    expect(exporter.export_dir).to eq dir
    expect(exporter.export_file_name).to eq file
    expect(exporter.export_file).to eq File.join(dir, file)
    expect(exporter.temp_file_name).to eq 'test_export.tmp'
    expect(exporter.temp_file).to eq File.join(dir, 'test_export.tmp')
  end

  context "when the export dir doesn't exist" do
    before { FileUtils.rm_rf(dir, :secure => true) }
    after  { FileUtils.rm_rf(dir, :secure => true) }

    it 'creates the directory' do
      expect(File.exist?(dir)).to be_falsey
      exporter.make_export_dir
      expect(File.exist?(dir)).to be_truthy
    end
  end

  describe '#run' do
    before do
      AdminPolicy.ensure_admin_policy_exists
      LocalAuthority.local_authority_models.each do |model|
        model.destroy_all
      end
    end

    after { FileUtils.rm_rf(dir, :secure => true) }

    # Create some different types of local authorities
    let!(:agent) { create(:agent, foaf_name: 'Mark') }
    let!(:justin) { create(:person, foaf_name: 'Justin') }
    let!(:alicia) { create(:person, foaf_name: 'Alicia') }
    let!(:devs) { create(:group, foaf_name: 'DCE Dev Team') }
    let!(:dce) { create(:organization, foaf_name: 'DCE') }
    let!(:tools) { create(:topic, label: ['hydra', 'blacklight', 'fedora', 'solr']) }
    let!(:fun) { create(:topic, label: ['happy hour', 'nerdy jokes']) }

    let(:headers) { ['type', 'id', 'public_uri', 'name', 'name', 'name', 'name'] }

    it 'exports the local authorities' do
      exporter.run

      export_file = File.join(dir, file)
      contents = File.readlines(export_file).map(&:strip)

      # The file should have 8 lines total
      expect(contents.count).to eq 8

      expect(contents[0].split(',')).to eq headers
      expect(contents[1].split(',')).to eq ['Agent', agent.id, agent.public_uri, agent.foaf_name]

      line2 = contents[2].split(',')
      line3 = contents[3].split(',')

      # We don't know what order they will be in.  Decide if
      # we should compare this line to "justin" or "alicia".
      person = line2[1] == justin.id ? justin : alicia
      expect(line2).to eq ['Person', person.id, person.public_uri, person.foaf_name]

      person = line3[1] == justin.id ? justin : alicia
      expect(line3).to eq ['Person', person.id, person.public_uri, person.foaf_name]

      expect(contents[4].split(',')).to eq ['Group', devs.id, devs.public_uri, devs.foaf_name]
      expect(contents[5].split(',')).to eq ['Organization', dce.id, dce.public_uri, dce.foaf_name]

      line6 = contents[6].split(',')
      line7 = contents[7].split(',')

      # We don't know what order the topics will be in.
      topic = line6[1] == fun.id ? fun : tools
      expect(line6).to eq ['Topic', topic.id, topic.public_uri] + topic.label

      topic = line7[1] == fun.id ? fun : tools
      expect(line7).to eq ['Topic', topic.id, topic.public_uri] + topic.label
    end
  end  # run

end
