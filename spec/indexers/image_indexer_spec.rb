require 'rails_helper'

describe ImageIndexer do
  subject { ImageIndexer.new(image).generate_solr_document }

  context "with a generic_file" do
    let(:generic_file) { GenericFile.new(id: 'bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3') }
    let(:image) { Image.new(generic_files: [generic_file]) }

    it "has images" do
      expect(subject['thumbnail_url_ssm']).to eq ['http://test.host/images/bf%2F74%2F27%2F75%2Fbf742775-2a24-46dc-889e-cca03b27b5f3%2Foriginal/full/300,/0/native.jpg']
      expect(subject['image_url_ssm']).to eq ['http://test.host/images/bf%2F74%2F27%2F75%2Fbf742775-2a24-46dc-889e-cca03b27b5f3%2Foriginal/full/600,/0/native.jpg']
      expect(subject['large_image_url_ssm']).to eq ['http://test.host/images/bf%2F74%2F27%2F75%2Fbf742775-2a24-46dc-889e-cca03b27b5f3%2Foriginal/full/1000,/0/native.jpg']
    end
  end

  describe 'Indexing dates' do
    context "with an issued date" do
      let(:image) { Image.new(issued_attributes: [{ start: ['1925-11'] }]) }

      it "indexes dates for display" do
        expect(subject['issued_ssm']).to eq "1925-11"
      end
    end

    context "with an issued date" do
      let(:copyrighted) { ['1913'] }
      let(:image) { Image.new(date_copyrighted_attributes: [{ start: copyrighted }]) }

      it "indexes dates for display" do
        expect(subject['date_copyrighted_ssm']).to eq copyrighted
      end
    end


    context "with issued.start and issued.finish" do
      let(:issued_start) { ['1917'] }
      let(:issued_end) { ['1923'] }
      let(:image) { Image.new(issued_attributes: [{ start: issued_start, finish: issued_end}]) }

      it "indexes dates for display" do
        expect(subject['issued_ssm']).to eq "1917 - 1923"
      end
    end
  end

  context 'with local and LOC rights holders' do
    let(:regents_uri) { RDF::URI.new("http://id.loc.gov/authorities/names/n85088322") }
    let(:valerie) { Agent.create(foaf_name: 'Valerie') }
    let(:valerie_uri) { RDF::URI.new(valerie.uri) }

    let(:image) { Image.new(rights_holder: [valerie_uri, regents_uri]) }

    it 'indexes with a label' do
      VCR.use_cassette('rights_holder') do
        expect(subject['rights_holder_ssim']).to eq [valerie_uri, regents_uri]
        expect(subject['rights_holder_label_tesim']).to eq ['Valerie', 'University of California (System). Regents']
      end
    end
  end
end
