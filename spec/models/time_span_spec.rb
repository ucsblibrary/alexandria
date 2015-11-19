require 'rails_helper'

describe TimeSpan do
  describe '#start' do
    before do
      subject.start = ['1930']
    end
    it 'has start' do
      expect(subject.start).to eq ['1930']
    end
  end

  context '#earliest_year' do
    before do
      subject.start = ['1930', '1912', '', '1920']
    end

    it 'finds the earliest year' do
      expect(subject.earliest_year).to eq '1912'
    end
  end

  describe '#display_label' do
    context 'when there is a label' do
      before { subject.label = ['circa 1956'] }

      it 'returns the label' do
        expect(subject.display_label).to eq 'circa 1956'
      end
    end

    context 'when there is no label' do
      context 'and there is a start date with no qualifier' do
        before { subject.start = ['1956'] }

        it 'returns the start date' do
          expect(subject.display_label).to eq '1956'
        end
      end

      context 'and there is an approximate start date' do
        before do
          subject.start = ['1956']
          subject.start_qualifier = [TimeSpan::APPROX]
        end

        it 'adds "circa" qualifier to the start date' do
          expect(subject.display_label).to eq 'ca. 1956'
        end
      end

      context 'and there is a questionable start date' do
        before do
          subject.start = ['1956']
          subject.start_qualifier = [TimeSpan::QUESTIONABLE]
        end

        it 'adds "circa" qualifier to the start date' do
          expect(subject.display_label).to eq 'ca. 1956'
        end
      end

      context 'and there is an finish date with no qualifier' do
        before { subject.finish = ['1956'] }

        it 'returns the finish date' do
          expect(subject.display_label).to eq '1956'
        end
      end

      context 'and there is an approximate finish date' do
        before do
          subject.finish = ['1956']
          subject.finish_qualifier = [TimeSpan::APPROX]
        end

        it 'adds "circa" qualifier to the finish date' do
          expect(subject.display_label).to eq 'ca. 1956'
        end
      end

      context 'and there is a questionable finish date' do
        before do
          subject.finish = ['1956']
          subject.finish_qualifier = [TimeSpan::QUESTIONABLE]
        end

        it 'adds "circa" qualifier to the finish date' do
          expect(subject.display_label).to eq 'ca. 1956'
        end
      end

      context 'and there is a range of dates with no qualifiers' do
        before do
          subject.start = ['1956']
          subject.finish = ['1958']
        end

        it 'returns the date range' do
          expect(subject.display_label).to eq '1956 - 1958'
        end
      end

      context 'and there is an approximate date range' do
        before do
          subject.start = ['1956']
          subject.start_qualifier = [TimeSpan::APPROX]
          subject.finish = ['1958']
          subject.finish_qualifier = [TimeSpan::APPROX]
        end

        it 'adds "circa" to the date range' do
          expect(subject.display_label).to eq 'ca. 1956 - ca. 1958'
        end
      end

      context 'and there is a questionable date range' do
        before do
          subject.start = ['1956']
          subject.start_qualifier = [TimeSpan::QUESTIONABLE]
          subject.finish = ['1958']
          subject.finish_qualifier = [TimeSpan::QUESTIONABLE]
        end

        it 'adds "circa" to the date range' do
          expect(subject.display_label).to eq 'ca. 1956 - ca. 1958'
        end
      end
    end
  end # display_label

  describe 'TimeSpan.qualifiers' do
    it 'has the expected qualifiers in order' do
      expect(TimeSpan.qualifiers).to eq(%w(approximate inferred questionable))
    end
  end
end
