# frozen_string_literal: true

require "rails_helper"
require "parse"

describe Parse::MODS do
  let(:parser) { described_class.new(file, Logger.new(STDOUT)) }
  let(:attributes) { parser.attributes }

  describe "Determine which kind of record it is:" do
    describe "for a collection:" do
      let(:file) do
        "#{fixture_path}/mods/sbhcmss78_FlyingAStudios_collection.xml"
      end

      it "knows it is a Collection" do
        expect(parser.model).to eq Collection
      end
    end

    describe "for an image:" do
      let(:file) { "#{fixture_path}/mods/cusbspcsbhc78_100239.xml" }

      it "knows it is an Image" do
        expect(parser.model).to eq Image
      end
    end
  end

  describe "#attributes for an Image record" do
    let(:ns_decl) { "xmlns='#{Mods::MODS_NS}'" }
    let(:file) { "#{fixture_path}/mods/cusbspcsbhc78_100239.xml" }

    it "finds metadata for the image" do
      expect(attributes[:description]).to(
        eq ["Another description", "Man with a smile eyes to camera."]
      )
      expect(attributes[:location]).to(
        eq ["http://id.loc.gov/authorities/names/n79081574"]
      )
      expect(attributes[:form_of_work]).to(
        eq([
             "http://vocab.getty.edu/aat/300134920",
             "http://vocab.getty.edu/aat/300046300",
           ])
      )
      expect(attributes[:extent]).to(
        eq ["1 photograph : glass plate negative ; 13 x 18 cm (5 x 7 format)"]
      )
      expect(attributes[:accession_number]).to eq ["cusbspcsbhc78_100239"]
      expect(attributes[:sub_location]).to(
        eq ["Department of Special Collections"]
      )
      expect(attributes[:citation]).to(
        eq ["[Identification of Item], Joel Conway "\
            "/ Flying A Studio Photograph Collection. SBHC Mss 78. "\
            "Department of Special Collections, UC Santa Barbara Library, "\
            "University of California, Santa Barbara.",]
      )
      acquisition_note = attributes[:notes_attributes].first
      expect(acquisition_note[:note_type]).to eq "acquisition"

      expect(acquisition_note[:value]).to(
        eq "Gift from Pat Eagle-Schnetzer and Ronald Conway, "\
           "and purchase from Joan Cota (Conway children), 2009."
      )

      expect(attributes[:description_standard]).to eq ["local"]
      expect(attributes[:series_name]).to eq ["Series 4: Glass Negatives"]

      expect(attributes[:restrictions]).to(
        eq ["Use governed by the UCSB Special Collections policy."]
      )

      expect(attributes[:copyright_status]).to(
        eq ["http://id.loc.gov/vocabulary/preservation/copyrightStatus/unk"]
      )

      expect(attributes[:license]).to(
        eq ["http://www.europeana.eu/rights/unknown/"]
      )

      expect(attributes[:institution]).to(
        eq ["http://id.loc.gov/vocabulary/organizations/cusb"]
      )
    end

    context "importing record origin" do
      it "correctly formats the record origin including the timestamp" do
        date = Time.utc(2014, 5, 20, 11, 34, 23)
        formatted_date = date.to_s(:iso8601)

        Timecop.freeze(date) do
          expect(attributes[:record_origin]).to(
            # rubocop:disable Metrics/LineLength
            eq ["#{formatted_date} Converted from CSV to MODS 3.4 using local mapping.",
                "#{formatted_date} #{Parse::MODS::ORIGIN_TEXT}",]
            # rubocop:enable Metrics/LineLength
          )
        end
      end
    end

    context "with a file that has a general (untyped) note" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110108.xml" }

      it "imports notes" do
        expect(attributes[:notes_attributes].first[:value]).to(
          eq "Title from item."
        )
        expect(attributes[:notes_attributes].second[:value]).to(
          eq(
            "Postcard caption: 60. Arlington Hotel, Sta. Barbara Quake 6-29-25."
          )
        )
      end
    end

    context "with a file that has a publisher" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110108.xml" }

      it "imports publisher" do
        expect(attributes[:publisher]).to eq ["[Cross & Dimmit Pictures]"]
      end
    end

    context "with a file that has a photographer" do
      let(:file) { "#{fixture_path}/mods/cusbmss228-p00003.xml" }

      it "imports photographer" do
        expect(attributes[:photographer]).to(
          eq ["http://id.loc.gov/authorities/names/n97003180"]
        )
      end
    end

    it "imports creator" do
      expect(attributes[:creator]).to(
        eq ["http://id.loc.gov/authorities/names/n87914041"]
      )
    end

    it "imports language" do
      expect(attributes[:language]).to(
        eq ["http://id.loc.gov/vocabulary/iso639-2/zxx"]
      )
    end

    it "imports work_type" do
      expect(attributes[:work_type]).to(
        eq ["http://id.loc.gov/vocabulary/resourceTypes/img"]
      )
    end

    it "imports digital origin" do
      expect(attributes[:digital_origin]).to eq ["digitized other analog"]
    end

    context "with a file that has coordinates" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110089.xml" }

      it "imports coordinates" do
        expect(attributes[:latitude]).to eq ["34.442982"]
        expect(attributes[:longitude]).to eq ["-119.657362"]
      end
    end

    it "finds metadata for the collection" do
      expect(attributes[:collection][:accession_number]).to eq ["SBHC Mss 78"]
      expect(attributes[:collection][:title]).to(
        eq ["Joel Conway / Flying A Studio photograph collection"]
      )
    end

    context "with a range of dateCreated" do
      it "imports created" do
        expect(attributes[:created_attributes]).to(
          eq(
            [{ start: ["1910"],
               finish: ["1919"],
               label: ["circa 1910s"],
               start_qualifier: ["approximate"],
               finish_qualifier: ["approximate"], },]
          )
        )
      end
    end

    context "without date_created" do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo>"\
        "<dateValid encoding=\"w3cdtf\">1989-12-01</dateValid>"\
        "</originInfo></mods>"
      end

      before do
        allow(parser).to receive(:model).and_return(Image)
        allow(parser).to(
          receive(:mods).and_return(Mods::Record.new.from_str(xml))
        )
      end

      it "doesn't return an attributes hash (would create an empty TimeSpan)" do
        expect(attributes[:created_attributes]).to eq []
      end
    end

    context "with a file that has a range of dateIssued" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110089.xml" }

      it "imports issued" do
        expect(attributes[:issued_attributes]).to(
          eq(
            [{ start: ["1900"],
               finish: ["1959"],
               label: ["circa 1900s-1950s"],
               start_qualifier: ["approximate"],
               finish_qualifier: ["approximate"], },]
          )
        )
      end
    end

    context "with a file that has a single dateIssued" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110108.xml" }

      it "imports issued" do
        expect(attributes[:issued_attributes]).to(
          eq(
            [{ start: ["1925"],
               finish: [],
               label: [],
               start_qualifier: [],
               finish_qualifier: [], },]
          )
        )
      end
    end

    context "with date_copyrighted" do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo>"\
        "<copyrightDate encoding=\"w3cdtf\">1985-12-01</copyrightDate>"\
        "</originInfo></mods>"
      end

      before do
        allow(parser).to receive(:model).and_return(Image)
        allow(parser).to(
          receive(:mods).and_return(Mods::Record.new.from_str(xml))
        )
      end

      it "imports date_copyrighted" do
        expect(attributes[:date_copyrighted_attributes]).to(
          eq(
            [{ start: ["1985-12-01"],
               finish: [],
               label: [],
               start_qualifier: [],
               finish_qualifier: [], },]
          )
        )
      end
    end

    context "with dateValid" do
      let(:parser) { described_class.new(nil) }
      let(:xml) do
        "<mods #{ns_decl}><originInfo>"\
        "<dateValid encoding=\"w3cdtf\">1989-12-01</dateValid>"\
        "</originInfo></mods>"
      end

      before do
        allow(parser).to receive(:model).and_return(Image)
        allow(parser).to(
          receive(:mods).and_return(Mods::Record.new.from_str(xml))
        )
      end

      it "imports date_valid" do
        expect(attributes[:date_valid_attributes]).to(
          eq(
            [{ start: ["1989-12-01"],
               finish: [],
               label: [],
               start_qualifier: [],
               finish_qualifier: [], },]
          )
        )
      end
    end

    context "with a file that has an alternative title" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110089.xml" }

      it "distinguishes between title and alternative title" do
        expect(attributes[:title]).to eq ["Patio, Gavit residence"]
        expect(attributes[:alternative]).to eq ["Lotusland"]
      end
    end

    context "with a file that has copyrightHolder" do
      let(:file) { "#{fixture_path}/mods/cusbmss228-p00001.xml" }

      it "finds the rights holder" do
        expect(attributes[:rights_holder]).to(
          eq ["http://id.loc.gov/authorities/names/n85088322"]
        )
      end
    end

    context "with a file that has placeTerm" do
      let(:file) { "#{fixture_path}/mods/cusbspcmss36_110089.xml" }

      it "reads the place" do
        expect(attributes[:place_of_publication]).to(
          eq ["Santa Barbara, California"]
        )
      end
    end
  end

  describe "#attributes for a Collection record" do
    let(:file) do
      "#{fixture_path}/mods/sbhcmss78_FlyingAStudios_collection.xml"
    end

    it "finds the metadata" do
      expect(attributes[:accession_number]).to eq ["SBHC Mss 78"]
      expect(attributes[:collector]).to(
        eq [{ name: "Conway, Joel", type: "personal" }]
      )
      expect(attributes[:created_attributes]).to(
        eq(
          [{ start: ["1910"],
             finish: ["1919"],
             label: ["circa 1910s"],
             start_qualifier: ["approximate"],
             finish_qualifier: ["approximate"], },]
        )
      )
      expect(attributes[:creator]).to be_nil

      expect(attributes[:description]).to(
        eq ["Black and white photographs relating to the Flying A Studios "\
            "(aka American Film Manufacturing Company), "\
            "a film company that operated in Santa Barbara (1912-1920).",]
      )
      expect(attributes[:extent]).to eq ["702 digital objects"]

      expect(attributes[:finding_aid]).to(
        eq ["http://www.oac.cdlib.org/findaid/ark:/13030/kt1j49r67t"]
      )

      expect(attributes[:form_of_work]).to(
        eq ["http://vocab.getty.edu/aat/300046300",
            "http://vocab.getty.edu/aat/300128343",]
      )

      expect(attributes[:language]).to(
        eq ["http://id.loc.gov/vocabulary/iso639-2/zxx"]
      )

      expect(attributes[:lc_subject]).to(
        eq ["http://id.loc.gov/authorities/names/n87914041",
            "http://id.loc.gov/authorities/subjects/sh85088047",
            "http://id.loc.gov/authorities/subjects/sh99005024",]
      )

      expect(attributes[:sub_location]).to(
        eq ["Department of Special Collections"]
      )

      expect(attributes[:title]).to(
        eq ["Joel Conway / Flying A Studio photograph collection"]
      )

      expect(attributes[:work_type].map(&:value)).to(
        eq ["http://id.loc.gov/vocabulary/resourceTypes/col",
            "http://id.loc.gov/vocabulary/resourceTypes/img",]
      )

      # TODO: There is another location in the fixture file
      # that doesn't have a valueURI.  How should that be
      # handled?
      expect(attributes[:location]).to(
        eq ["http://id.loc.gov/authorities/names/n79041717"]
      )
    end

    context "importing record origin" do
      it "correctly formats the record origin including the timestamp" do
        date = Time.utc(2014, 5, 20, 11, 34, 23)
        formatted_date = date.to_s(:iso8601)

        Timecop.freeze(date) do
          expect(attributes[:record_origin]).to(
            eq ["#{formatted_date} Human created",
                "#{formatted_date} #{Parse::MODS::ORIGIN_TEXT}",]
          )
        end
      end
    end
  end
end
