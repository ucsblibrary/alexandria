require 'rails_helper'

describe Note do
  describe 'properties' do
    let(:type)  { 'A note type' }
    let(:value) { 'A note value' }

    before do
      subject.note_type = type
      subject.value = value
    end

    it 'has type and value' do
      expect(subject.note_type).to eq [type]
      expect(subject.value).to eq [value]
    end
  end
end
