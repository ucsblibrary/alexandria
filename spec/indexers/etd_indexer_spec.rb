require 'rails_helper'

describe ETDIndexer do
  let(:document) { described_class.new(etd).generate_solr_document }
  subject { document }

  context 'with a generic_file' do
    before do
      allow(etd).to receive_messages(generic_file_ids: ['bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3'])
    end
    let(:etd) { ETD.new }

    it 'has downloads' do
      expect(subject['generic_file_ids_ssim']).to eq ['bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3']
    end
  end

  describe 'Indexing copyright' do
    let(:copyrighted) { ['2014'] }
    let(:etd) do
      ETD.new(date_copyrighted: copyrighted, rights_holder: ['Samantha Lauren'])
    end
    let(:subject) { document['copyright_ssm'] }

    it { is_expected.to eq 'Samantha Lauren, 2014' }
  end

  describe 'Indexing author (as creator facet)' do
    let(:etd) { ETD.new(author: ['Kfir Lazare Sargent']) }
    subject { document['creator_label_sim'] }

    it { is_expected.to eq ['Kfir Lazare Sargent'] }
  end

  describe 'Indexing dissertation' do
    let(:dissertation_degree) { ['Ph.D.'] }
    let(:dissertation_institution) { ['University of California, Santa Barbara'] }
    let(:dissertation_year) { ['2014'] }

    let(:etd) do
      ETD.new(dissertation_degree: dissertation_degree,
              dissertation_institution: dissertation_institution,
              dissertation_year: dissertation_year)
    end
    let(:subject) { document['dissertation_ssm'] }

    it { is_expected.to eq 'Ph.D.--University of California, Santa Barbara, 2014' }
  end

  describe "indexing department as a facet" do
    let(:etd) do
      ETD.new(degree_grantor: ['University of California, Santa Barbara. Mechanical Engineering'])
    end
    let(:subject) { document['department_sim'] }
    it { is_expected.to eq ['Mechanical Engineering'] }
  end

  describe 'Indexing dates' do
    context 'with an issued date' do
      let(:etd) { ETD.new(issued: ['1925-11-10', '1931']) }

      it 'indexes dates for display' do
        expect(subject['issued_ssm']).to eq ['1925-11-10', '1931']
      end

      it 'makes a sortable date field' do
        expect(subject['date_si']).to eq '1925-11-10'
      end

      it 'makes a facetable year field' do
        expect(subject['year_iim']).to eq [1925, 1931]
      end
    end

    describe 'with multiple types of dates' do
      let(:created) { ['1911'] }
      let(:issued) { ['1912'] }
      let(:copyrighted) { ['1913'] }
      let(:other) { ['1914'] }
      let(:valid) { ['1915'] }

      let(:etd) do
        ETD.new(created_attributes: [{ start: created }],
                issued: issued, date_copyrighted: copyrighted,
                date_other_attributes: [{ start: other }],
                date_valid_attributes: [{ start: valid }])
      end

      it 'indexes dates for display' do
        expect(subject['date_other_ssm']).to eq other
        expect(subject['date_valid_ssm']).to eq valid
      end

      context 'with both issued and created dates' do
        it "chooses 'created' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq created.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to eq created.map(&:to_i)
        end
      end

      context 'with issued date, but not created date' do
        let(:created) { nil }

        it "chooses 'issued' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq issued.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to eq issued.map(&:to_i)
        end
      end

      context 'with neither created nor issued date' do
        let(:created) { nil }
        let(:issued) { nil }

        it "chooses 'copyrighted' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq copyrighted.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to eq copyrighted.map(&:to_i)
        end
      end

      context 'with only date_other or date_valid' do
        let(:created) { nil }
        let(:issued) { nil }
        let(:copyrighted) { nil }

        it "chooses 'date_other' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq other.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to eq other.map(&:to_i)
        end
      end
    end # context 'with multiple types of dates'
  end # Indexing dates
end
