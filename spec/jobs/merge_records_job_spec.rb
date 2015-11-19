require 'rails_helper'

RSpec.describe MergeRecordsJob, type: :job do
  describe '#perform' do
    context 'with missing record' do
      it 'raises an error' do
        expect do
          MergeRecordsJob.perform_now('bad_ID', 'bad_ID_2')
        end.to raise_error(ActiveFedora::ObjectNotFoundError)
      end
    end

    context 'with good inputs' do
      let(:joel) { create(:person, foaf_name: 'Joel Conway', id: 'joel') }
      let(:conway) { create(:person, foaf_name: 'Conway, J', id: 'conway') }

      let(:image) { create(:image, id: 'image', creator: [conway], lc_subject: [conway]) }

      before do
        AdminPolicy.ensure_admin_policy_exists
        [joel, conway, image] # create the records
      end

      it 'calls the service that merges the records' do
        merge_service = double(run: true)
        expect(MergeRecordsService).to receive(:new).with(conway, joel) { merge_service }
        expect(merge_service).to receive(:run)
        MergeRecordsJob.perform_now(conway.id, joel.id)
      end
    end
  end # describe #perform
end
