# frozen_string_literal: true

require "rails_helper"

describe ETDIndexer do
  subject { document }

  let(:document) { described_class.new(etd).generate_solr_document }

  context "with a file_set" do
    before do
      allow(etd).to(
        receive_messages(
          member_ids: ["bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3"]
        )
      )
    end

    let(:etd) { ETD.new }

    it "has downloads" do
      expect(subject["member_ids_ssim"]).to(
        eq ["bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3"]
      )
    end
  end

  describe "Indexing copyright" do
    subject { document["copyright_ssm"] }

    let(:etd) do
      ETD.new(
        date_copyrighted: ["2014"],
        rights_holder: [Agent.create(foaf_name: "Samantha Lauren").uri]
      )
    end

    it { is_expected.to eq "Samantha Lauren, 2014" }
  end

  describe "Indexing author (as contributor facet)" do
    subject { document["all_contributors_label_sim"] }

    let(:etd) do
      ETD.new(author: [Agent.create(foaf_name: "Kfir Lazare Sargent").uri])
    end

    it { is_expected.to eq ["Kfir Lazare Sargent"] }
  end

  describe "Indexing dissertation" do
    let(:dissertation_degree) { ["Ph.D."] }
    let(:dissertation_institution) do
      ["University of California, Santa Barbara"]
    end
    let(:dissertation_year) { ["2014"] }

    let(:etd) do
      ETD.new(dissertation_degree: dissertation_degree,
              dissertation_institution: dissertation_institution,
              dissertation_year: dissertation_year)
    end
    let(:subject) { document["dissertation_ssm"] }

    it do
      expect(subject).to eq "Ph.D.--University of California, Santa Barbara, 2014"
    end
  end

  describe "missing dissertation information" do
    let(:dissertation_degree) { ["Ph.D."] }
    let(:dissertation_institution) { [""] }
    let(:dissertation_year) { [""] }

    let(:etd) do
      ETD.new(dissertation_degree: dissertation_degree,
              dissertation_institution: dissertation_institution,
              dissertation_year: dissertation_year)
    end
    let(:subject) { document["dissertation_ssm"] }

    it { is_expected.to eq nil }
  end

  describe "indexing department as a facet" do
    subject { document["department_sim"] }

    let(:etd) do
      ETD.new(degree_grantor: ["University of California, Santa Barbara. "\
                               "Mechanical Engineering"])
    end

    it { is_expected.to eq ["Mechanical Engineering"] }
  end

  describe "Indexing dates" do
    context "with an issued date" do
      let(:etd) { ETD.new(issued: %w[1925-11-10 1931]) }

      it "indexes dates for display" do
        expect(subject["issued_ssm"]).to contain_exactly("1925-11-10", "1931")
      end

      it "makes a sortable date field" do
        expect(subject["date_si"]).to eq "1925-11-10"
      end

      it "makes a facetable year field" do
        expect(subject["year_iim"]).to eq [1925, 1931]
      end
    end

    describe "with multiple types of dates" do
      let(:created) { ["1911"] }
      let(:issued) { ["1912"] }
      let(:copyrighted) { ["1913"] }
      let(:other) { ["1914"] }
      let(:valid) { ["1915"] }

      let(:etd) do
        ETD.new(created_attributes: [{ start: created }],
                issued: issued, date_copyrighted: copyrighted,
                date_other_attributes: [{ start: other }],
                date_valid_attributes: [{ start: valid }])
      end

      it "indexes dates for display" do
        expect(subject["date_other_ssm"]).to eq other
        expect(subject["date_valid_ssm"]).to eq valid
      end

      context "with both issued and created dates" do
        it "chooses 'created' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq created.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to(
            eq created.map(&:to_i)
          )
        end
      end

      context "with issued date, but not created date" do
        let(:created) { nil }

        it "chooses 'issued' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq issued.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to(
            eq issued.map(&:to_i)
          )
        end
      end

      context "with neither created nor issued date" do
        let(:created) { nil }
        let(:issued) { nil }

        it "chooses 'copyrighted' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq copyrighted.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to(
            eq copyrighted.map(&:to_i)
          )
        end
      end

      context "with only date_other or date_valid" do
        let(:created) { nil }
        let(:issued) { nil }
        let(:copyrighted) { nil }

        it "chooses 'date_other' date for sort/facet date" do
          expect(subject[ObjectIndexer::SORTABLE_DATE]).to eq other.first
          expect(subject[ObjectIndexer::FACETABLE_YEAR]).to(
            eq other.map(&:to_i)
          )
        end
      end
    end # context 'with multiple types of dates'
  end # Indexing dates
end
