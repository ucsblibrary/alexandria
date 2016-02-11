require 'rails_helper'

describe ImageIndexer do
  before do
    ActiveFedora::Cleaner.clean!
  end
  subject { ImageIndexer.new(image).generate_solr_document }

  context 'with a file_set' do
    let(:file_set) { double(files: [file]) }
    let(:file) { double(id: 's1/78/4k/72/s1784k724/files/6185235a-79b2-4c29-8c24-4d6ad9b11470') }
    before do
      allow(image).to receive_messages(file_sets: [file_set])
    end
    let(:image) { Image.new }

    it 'has images' do
      expect(subject['thumbnail_url_ssm']).to eq ['http://test.host/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/300,/0/default.jpg']
      expect(subject['image_url_ssm']).to eq ['http://test.host/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/600,/0/default.jpg']
      expect(subject['large_image_url_ssm']).to eq ['http://test.host/images/s1%2F78%2F4k%2F72%2Fs1784k724%2Ffiles%2F6185235a-79b2-4c29-8c24-4d6ad9b11470/full/1000,/0/default.jpg']
    end
  end

  describe 'Indexing dates' do
    context 'with an issued date' do
      let(:image) { Image.new(issued_attributes: [{ start: ['1925-11'] }]) }

      it 'indexes dates for display' do
        expect(subject['issued_ssm']).to eq '1925-11'
      end
    end

    context 'with an issued date' do
      let(:copyrighted) { ['1913'] }
      let(:image) { Image.new(date_copyrighted_attributes: [{ start: copyrighted }]) }

      it 'indexes dates for display' do
        expect(subject['date_copyrighted_ssm']).to eq copyrighted
      end
    end

    context 'with issued.start and issued.finish' do
      let(:issued_start) { ['1917'] }
      let(:issued_end) { ['1923'] }
      let(:image) { Image.new(issued_attributes: [{ start: issued_start, finish: issued_end }]) }

      it 'indexes dates for display' do
        expect(subject['issued_ssm']).to eq '1917 - 1923'
      end
    end
  end

  context 'with location' do
    let(:location) { RDF::URI('http://id.loc.gov/authorities/subjects/sh85072779') }
    let(:image) { Image.new(location: [location]) }
    it "indexes a label" do
      VCR.use_cassette('location') do
        expect(subject['location_sim']).to eq [location]
        expect(subject['location_label_sim']).to eq ['Kodiak Island (Alaska)']
        expect(subject['location_label_tesim']).to eq ['Kodiak Island (Alaska)']
      end
    end
  end

  context 'with local and LOC rights holders' do
    let(:regents_uri) { RDF::URI('http://id.loc.gov/authorities/names/n85088322') }
    let(:valerie) { Agent.create(foaf_name: 'Valerie') }
    let(:valerie_uri) { RDF::URI(valerie.uri) }

    let(:image) { Image.new(rights_holder: [valerie_uri, regents_uri]) }

    before do
      AdminPolicy.ensure_admin_policy_exists
    end

    it 'indexes with a label' do
      VCR.use_cassette('rights_holder') do
        expect(subject['rights_holder_ssim']).to eq [valerie_uri, regents_uri]
        expect(subject['rights_holder_label_tesim']).to eq ['Valerie', 'University of California (System). Regents']
      end
    end
  end
end
