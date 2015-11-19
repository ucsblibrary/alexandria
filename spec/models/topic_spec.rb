require 'rails_helper'

describe Topic do
  let(:topic) { Topic.new(label: ['Birds of California']) }

  describe '#rdf_label' do
    it 'has a label' do
      expect(topic.rdf_label).to eq ['Birds of California']
    end
  end
end
