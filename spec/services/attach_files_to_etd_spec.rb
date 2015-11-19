require 'rails_helper'

describe AttachFilesToETD do
  describe 'run' do
    let(:file) { 'Plunkett_ucsb_0035D_11862.pdf' }
    let(:zip_path) { 'fake_file.zip' }
    let(:etd) { ETD.create }
    let(:file_struct) do
      ZipfileService::ExtractedFiles.new(
        "#{Rails.root}/spec/fixtures/pdf/sample.pdf",
        "#{Rails.root}/spec/fixtures/proquest/Johnson_ucsb_0035N_12164_DATA.xml",
        ["#{Rails.root}/spec/fixtures/images/cusbspcmss36_110108_1_a.tif",
         "#{Rails.root}/spec/fixtures/images/cusbspcmss36_110108_2_a.tif"],
      )
    end

    before do
      AdminPolicy.ensure_admin_policy_exists
      allow_any_instance_of(ZipfileService).to receive(:extract_files).and_return(file_struct)
      described_class.run(etd, file)
    end

    it 'attaches files' do
      expect(etd.generic_files).to all(be_kind_of GenericFile)
      expect(etd.generic_files[0].original.size).to eq 218_882
      expect(etd.generic_files[1].original.mime_type).to eq 'image/tiff'
      expect(etd.generic_files[2].original.mime_type).to eq 'image/tiff'

      expect(etd.proquest.size).to eq 5564
    end

    it 'adds metadata from the ProQuest file to the ETD' do
      expect(etd.embargo_release_date).to eq Date.parse('2016/06/11')
      expect(etd.visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
      expect(etd.visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
      expect(etd.under_embargo?).to eq true
    end
  end
end
