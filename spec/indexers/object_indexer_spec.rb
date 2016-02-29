require 'rails_helper'

describe ObjectIndexer do
  subject { described_class.new(image).generate_solr_document }

  describe 'Indexing dates' do
    context 'with an issued date' do
      let(:image) { Image.new(issued_attributes: [{ start: ['1925-11'] }]) }

      it 'makes a sortable date field' do
        expect(subject['date_si']).to eq '1925-11'
      end

      it 'makes a facetable year field' do
        expect(subject['year_iim']).to eq [1925]
      end
    end

    context 'with issued.start and issued.finish' do
      let(:issued_start) { ['1917'] }
      let(:issued_end) { ['1923'] }
      let(:image) { Image.new(issued_attributes: [{ start: issued_start, finish: issued_end }]) }

      it 'makes a sortable date field' do
        expect(subject['date_si']).to eq '1917'
      end

      it 'makes a facetable year field' do
        expect(subject['year_iim']).to eq [1917, 1918, 1919, 1920, 1921, 1922, 1923]
      end
    end

    context 'with created.start and created.finish' do
      let(:created_start) { ['1917'] }
      let(:created_end) { ['1923'] }
      let(:image) { Image.new(created_attributes: [{ start: created_start, finish: created_end }]) }

      it 'indexes dates for display' do
        expect(subject['created_ssm']).to eq '1917 - 1923'
      end

      it 'makes a sortable date field' do
        expect(subject['date_si']).to eq '1917'
      end

      it 'makes a facetable year field' do
        expect(subject['year_iim']).to eq [1917, 1918, 1919, 1920, 1921, 1922, 1923]
      end
    end

    describe 'with multiple types of dates' do
      let(:created) { ['1911'] }
      let(:issued) { ['1912'] }
      let(:copyrighted) { ['1912'] }
      let(:other) { ['1914'] }
      let(:valid) { ['1915'] }

      let(:image) do
        Image.new(created_attributes: [{ start: created }],
                  date_copyrighted_attributes: [{ start: copyrighted }],
                  issued_attributes:  [{ start: issued }],
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
    end

    context 'with multiple created dates' do
      let(:earliest) { ['1915'] }
      let(:mid_1)    { ['1917'] }
      let(:mid_2)    { ['1921'] }
      let(:latest)   { ['1923'] }

      let(:image) do
        Image.new(created_attributes: [
                    { start: mid_2, finish: latest },
                    { start: earliest, finish: mid_1 },
                  ])
      end

      it 'makes a sortable date field' do
        expect(subject['date_si']).to eq earliest.first
      end

      it 'makes a facetable year field' do
        expect(subject['year_iim']).to eq [1915, 1916, 1917, 1921, 1922, 1923]
      end
    end
  end # Indexing dates

  context 'with rights' do
    let(:pd_uri) { RDF::URI.new('http://creativecommons.org/publicdomain/mark/1.0/') }
    let(:by_uri) { RDF::URI.new('http://creativecommons.org/licenses/by/4.0/') }
    let(:edu_uri) { RDF::URI.new('http://opaquenamespace.org/ns/rights/educational/') }
    let(:image) { Image.new(license: [pd_uri, by_uri, edu_uri]) }

    it 'indexes with a label' do
      VCR.use_cassette('creative_commons') do
        expect(subject['license_tesim']).to eq [pd_uri.to_s, by_uri.to_s, edu_uri.to_s]
        expect(subject['license_label_tesim']).to eq ['Public Domain Mark 1.0', 'Attribution 4.0 International', 'Educational Use Permitted']
      end
    end
  end

  context 'with copyright_status' do
    let(:public_domain_uri) { RDF::URI.new('http://id.loc.gov/vocabulary/preservation/copyrightStatus/pub') }
    let(:copyright_uri) { RDF::URI.new('http://id.loc.gov/vocabulary/preservation/copyrightStatus/cpr') }
    let(:unknown_uri) { RDF::URI.new('http://id.loc.gov/vocabulary/preservation/copyrightStatus/unk') }

    let(:image) { Image.new(copyright_status: [public_domain_uri, copyright_uri, unknown_uri]) }

    it 'indexes with a label' do
      VCR.use_cassette('copyright_status') do
        expect(subject['copyright_status_tesim']).to eq [public_domain_uri, copyright_uri, unknown_uri]
        expect(subject['copyright_status_label_tesim']).to eq ['public domain', 'copyrighted', 'unknown']
      end
    end
  end

  context 'with an ark' do
    let(:image) { Image.new(identifier: ['ark:/99999/fk4123456']) }
    it 'indexes ark for display' do
      expect(subject['identifier_ssm']).to eq ['ark:/99999/fk4123456']
    end
  end

  context 'with a title' do
    let(:image) { Image.new(title: ['War and Peace']) }

    it 'should have a title' do
      expect(subject['title_tesim']).to eq ['War and Peace']
    end
  end

  context 'with subject' do
    let(:lc_subject) { [RDF::URI.new('http://id.loc.gov/authorities/subjects/sh85062487')] }
    let(:image) { Image.new(lc_subject: lc_subject) }

    it 'should have a subject' do
      VCR.use_cassette('lc_subject_hotels') do
        expect(subject['lc_subject_tesim']).to eq ['http://id.loc.gov/authorities/subjects/sh85062487']
        expect(subject['lc_subject_label_tesim']).to eq ['Hotels']
      end
    end
  end

  context 'with many types of creator/contributors' do
    let(:creator) { [RDF::URI.new('http://id.loc.gov/authorities/names/n87914041')] }
    let(:singer) { [RDF::URI.new('http://id.loc.gov/authorities/names/n81053687')] }
    let(:person) { Person.create(foaf_name: 'Valerie') }
    let(:author) { ['Frank'] }
    let(:photographer) { [RDF::URI.new(person.uri)] }
    let(:image) { Image.new(author: author, creator: creator, singer: singer, photographer: photographer) }

    before { AdminPolicy.ensure_admin_policy_exists }

    it 'has a creator' do
      VCR.use_cassette('lc_names_american_film') do
        expect_any_instance_of(ContributorIndexer).to receive(:generate_solr_document) do |_, solr_doc|
          solr_doc.merge!('contributors' => 'this', 'sorted_creator' => 'that')
        end
        expect(subject['creator_tesim']).to eq ['http://id.loc.gov/authorities/names/n87914041']
        # The *_label_tesim is the result of the DeepIndexer
        expect(subject['creator_label_tesim']).to eq ['American Film Manufacturing Company']
        expect(subject['author_label_tesim']).to eq ['Frank']
        expect(subject['contributors']).to eq 'this'
        expect(subject['sorted_creator']).to eq 'that'
      end
    end
  end

  context 'with collections' do
    let(:image) { create(:image) }
    let!(:long_books) { Collection.create!(title: ['Long Books'], ordered_members: [image]) }
    let!(:boring_books) { Collection.create!(title: ['Boring Books'], ordered_members: [image]) }

    it 'has collections' do
      expect(subject['collection_ssim']).to match_array [boring_books.id, long_books.id]
      expect(subject['collection_label_ssim']).to include 'Long Books', 'Boring Books'
    end
  end

  context 'with notes' do
    let!(:acq_note) { { note_type: 'acquisition', value: 'Acq Note' } }
    let!(:cit_note) { { note_type: 'preferred citation', value: 'Citation Note' } }

    let(:image) { Image.new(notes_attributes: [acq_note, cit_note]) }

    it 'indexes with labels' do
      expect(subject['note_label_tesim']).to include(acq_note[:value], cit_note[:value])
    end
  end

  context 'with digital origin' do
    let(:dig_orig) { 'origin' }
    let(:image) { Image.create(digital_origin: [dig_orig]) }

    it 'indexes' do
      expect(subject['digital_origin_tesim']).to eq [dig_orig]
    end
  end
end
