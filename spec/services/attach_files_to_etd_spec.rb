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
         "#{Rails.root}/spec/fixtures/images/cusbspcmss36_110108_2_a.tif"]
      )
    end

    before do
      allow_any_instance_of(ZipfileService).to receive(:extract_files).and_return(file_struct)

      # squelch output
      allow($stdout).to receive(:puts)

      described_class.run(etd, nil, file)
    end

    it 'attaches files with admin_policy and embargo and adds metadata from ProQuest' do
      expect(etd.file_sets).to all(be_kind_of FileSet)
      expect(etd.file_sets[0].original_file.size).to eq 218_882
      expect(etd.file_sets[0].admin_policy_id).to eq AdminPolicy::DISCOVERY_POLICY_ID
      expect(etd.file_sets[1].original_file.mime_type).to eq 'image/tiff'
      expect(etd.file_sets[2].original_file.mime_type).to eq 'image/tiff'

      expect(etd.proquest.size).to eq 6005

      expect(etd.embargo_release_date).to eq Date.parse('2016/06/11')
      expect(etd.visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
      expect(etd.file_sets[0].visibility_during_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::DISCOVERY_POLICY_ID)
      expect(etd.visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
      expect(etd.file_sets[0].visibility_after_embargo.id).to eq ActiveFedora::Base.id_to_uri(AdminPolicy::PUBLIC_CAMPUS_POLICY_ID)
      expect(etd.under_embargo?).to eq true
      expect(etd.file_sets[0].under_embargo?).to eq true
    end
  end
end
