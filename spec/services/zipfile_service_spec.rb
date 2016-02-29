require 'rails_helper'

describe ZipfileService do
  let(:service) { described_class.new('Murray_ucsb_0035D_12159.pdf') }

  describe '#wildcard_zip' do
    subject { service.send(:wildcard_zip) }
    it { is_expected.to eq "#{Settings.proquest_directory}/*.zip" }
  end

  describe '#extract_files' do
    before do
      allow(service).to receive(:find_zip_file).and_return('foo.zip')
      allow(service).to receive(:run_unzip).and_return(
        "Archive:  /opt/download_root/proquest/etdadmin_upload_292976.zip
  inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159.pdf
  inflating: /tmp/jcoyne/Murray_ucsb_0035D_12159_DATA.xml
  inflating: /tmp/jcoyne/SupplementalFile1.pdf
  inflating: /tmp/jcoyne/SupplementalFile2.pdf
  inflating: /tmp/jcoyne/SupplementalFile3.pdf
")
    end
    let(:dir) { Dir.mktmpdir }

    subject { service.extract_files(dir) }
    it do
      is_expected.to eq ZipfileService::ExtractedFiles.new(
        '/tmp/jcoyne/Murray_ucsb_0035D_12159.pdf',
        '/tmp/jcoyne/Murray_ucsb_0035D_12159_DATA.xml',
        ['/tmp/jcoyne/SupplementalFile1.pdf',
         '/tmp/jcoyne/SupplementalFile2.pdf',
         '/tmp/jcoyne/SupplementalFile3.pdf']
      )
    end
  end
end
