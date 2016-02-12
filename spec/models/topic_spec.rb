require 'rails_helper'

describe Topic do
  let(:topic) { Topic.new(label: ['Birds of California']) }

  describe '#rdf_label' do
    it 'has a label' do
      expect(topic.rdf_label).to eq ['Birds of California']
    end
  end

  describe '#in_vocab?' do
    subject { topic.in_vocab? }
    it { is_expected.to be true }
  end
end
