# frozen_string_literal: true

require "rails_helper"
require "proquest"

describe Proquest::XML do
  let(:attributes) do
    described_class.attributes(Nokogiri::XML(File.read(file)))
  end

  describe "#attributes" do
    context "a record that has <embargo_code>" do
      let(:file) do
        "#{fixture_path}/proquest/Johnson_ucsb_0035N_12164_DATA.xml"
      end

      it "collects attributes for the ETD record" do
        expect(attributes[:embargo_code]).to eq "3"
        expect(attributes[:DISS_accept_date]).to eq "01/01/2014"
        expect(attributes[:DISS_agreement_decision_date]).to(
          eq "2020-06-11 23:12:18"
        )
        expect(attributes[:DISS_delayed_release]).to eq "2 years"
        expect(attributes[:embargo_remove_date]).to eq nil
        expect(attributes[:DISS_access_option]).to eq "Campus use only"
      end
    end

    context "a record that has <DISS_sales_restriction>" do
      let(:file) { "#{fixture_path}/proquest/Button_ucsb_0035D_11990_DATA.xml" }

      it "collects attributes for the ETD record" do
        expect(attributes[:embargo_code]).to eq "4"
        expect(attributes[:DISS_accept_date]).to eq "01/01/2013"
        expect(attributes[:embargo_remove_date]).to eq "2099-04-24 00:00:00"
      end
    end

    describe "copyright fields" do
      let(:file) { "#{fixture_path}/proquest/Miggs_ucsb_0035D_12446_DATA.xml" }

      it "collects attributes for the ETD record" do
        expect(attributes[:rights_holder]).to eq ["Martin Miggs"]
        expect(attributes[:date_copyrighted]).to eq [2014]
      end
    end
  end # describe #attributes

  describe "#metadata_attribs" do
    let(:file) { "#{fixture_path}/proquest/Johnson_ucsb_0035N_12164_DATA.xml" }
    let(:xml) { Nokogiri::XML(File.read(file)) }
    let(:metadata_attribs) do
      described_class.metadata_attribs(xml)
    end

    it "collects ETD title" do
      expect(metadata_attribs[:title]).to eq(["Fear of Heights"])
    end

    it "collects ETD author" do
      expect(metadata_attribs[:author])
        .to eq([{ type: "agent", name: "Johnson, Angelina" }])
    end

    it "collects ETD degree_supervisor" do
      expect(metadata_attribs[:degree_supervisor])
        .to eq([{ type: "agent", name: "Meowmers Catface" }])
    end

    it "collects ETD degree_grantor" do
      ucsb = "University of California, Santa Barbara.Psychology"
      expect(metadata_attribs[:degree_grantor]).to eq([{ type: "organization",
                                                         name: ucsb, },])
    end

    it "collects ETD created_attributes" do
      expect(metadata_attribs[:created_attributes]).to eq([{ start: ["2014"] }])
    end

    it "collects ETD dissertation_degree" do
      expect(metadata_attribs[:dissertation_degree]).to eq(["M.A."])
    end

    it "collects ETD dissertation_year" do
      expect(metadata_attribs[:dissertation_year]).to eq(["2014"])
    end

    it "collects ETD dissertation_institution" do
      expect(metadata_attribs[:dissertation_institution]).to eq([""])
    end

    it "collects ETD issued" do
      expect(metadata_attribs[:issued]).to eq(["2014"])
    end

    it "collects ETD marc_subjects" do
      expect(metadata_attribs[:marc_subjects]).to eq(["Psychology"])
    end

    it "collects ETD keywords" do
      expect(metadata_attribs[:keywords]).to eq([])
    end

    it "collects ETD place_of_publication" do
      expect(metadata_attribs[:place_of_publication])
        .to eq(["[Santa Barbara, Calif.]"])
    end

    it "collects ETD publisher" do
      expect(metadata_attribs[:publisher])
        .to eq(["University of California, Santa Barbara"])
    end

    it "collects ETD work_type" do
      expect(metadata_attribs[:work_type])
        .to eq([{ _rdf: ["http://id.loc.gov/vocabulary/resourceTypes/txt"] }])
    end

    it "collects ETD genre" do
      expect(metadata_attribs[:form_of_work])
        .to eq([RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85038494")])
    end

    describe ".language" do
      describe "with unknown language" do
        it "is empty" do
          xml = Nokogiri::XML.parse("<DISS_language>blah</DISS_language>")
          expect(described_class.language(xml)).to be_empty
        end
      end

      describe "with unknown iso code" do
        it "is empty" do
          allow(described_class).to receive(:to_iso639_2).with(str: "en")
            .and_return("om")
          expect(described_class.language(xml)).to be_empty
        end
      end

      it "collects ETD language" do
        expect(metadata_attribs[:language])
          .to eq([{ _rdf: ["http://id.loc.gov/vocabulary/iso639-2/eng"] }])
      end
    end
  end
end
