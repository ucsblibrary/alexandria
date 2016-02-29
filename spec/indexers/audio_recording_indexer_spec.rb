require 'rails_helper'

describe AudioRecordingIndexer do
  subject { described_class.new(audio).generate_solr_document }

  describe 'Indexing dates' do
    context 'with an issued date' do
      let(:audio) { AudioRecording.new(issued_attributes: [{ start: ['1925'] }]) }

      it 'indexes dates for display' do
        expect(subject['issued_ssm']).to eq '1925'
      end
    end

    context 'with issued.start and issued.finish' do
      let(:issued_start) { ['1917'] }
      let(:issued_end) { ['1923'] }
      let(:audio) { AudioRecording.new(issued_attributes: [{ start: issued_start, finish: issued_end, start_qualifier: 'approximate' }]) }

      it 'indexes dates for display' do
        expect(subject['issued_ssm']).to eq 'ca. 1917 - 1923'
      end
    end
  end
end
