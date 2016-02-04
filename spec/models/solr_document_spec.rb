require 'rails_helper'

describe SolrDocument do
  context 'for an image' do
    let(:image) { create(:image) }
    let(:document) { SolrDocument.new(id: image.id, identifier_ssm: ['ark:/99999/fk4v989d9j'], has_model_ssim: [Image.to_class_uri]) }

    describe '#ark' do
      subject { document.ark }
      it { is_expected.to eq 'ark:/99999/fk4v989d9j' }
    end

    describe '#etd?' do
      subject { document.etd? }
      it { is_expected.to be false }
    end

    describe '#public_uri' do
      subject { document.public_uri }
      it { is_expected.to be nil }
    end
  end

  context 'for an etd' do
    let(:etd_document) { SolrDocument.new(id: 'foobar', has_model_ssim: [ETD.to_class_uri]) }

    describe '#etd?' do
      subject { etd_document.etd? }
      it { is_expected.to be true }
    end

    describe 'file_sets' do
      subject { etd_document.file_sets }
      context 'with file sets' do
        let(:file_set_document) { SolrDocument.new(id: 'bf/74/27/75/bf742775-2a24-46dc-889e-cca03b27b5f3') }
        before do
          etd_document['member_ids_ssim'] = [file_set_document.id]
          ActiveFedora::SolrService.add(file_set_document)
          ActiveFedora::SolrService.commit
        end

        it 'looks up the file sets' do
          expect(subject.map(&:id)).to eq [file_set_document.id]
        end
      end

      context 'without file sets' do
        it { is_expected.to be_empty }
      end
    end
  end

  describe '#to_param' do
    let(:noid) { 'f123456789' }
    let(:id)   { 'f123456789' }

    subject { document.to_param }

    context 'for an object with an ARK' do
      let(:document) { SolrDocument.new(id: id, identifier_ssm: ["ark:/99999/#{noid}"]) }

      it 'converts the ark to a noid' do
        expect(subject).to eq noid
      end
    end

    context 'for an object without an ARK' do
      let(:document) { SolrDocument.new(id: id, identifier_ssm: nil) }
      it 'converts the id to a noid' do
        expect(subject).to eq noid
      end
    end
  end

  describe '#after_embargo_status' do
    before { AdminPolicy.ensure_admin_policy_exists }
    let(:document) do
      SolrDocument.new(
        visibility_during_embargo_ssim: ['authorities/policies/ucsb_on_campus'],
        visibility_after_embargo_ssim: ['authorities/policies/public'],
        embargo_release_date_dtsi: '2010-10-10T00:00:00Z',
      )
    end
    subject { document.after_embargo_status }
    it { is_expected.to eq ' - Becomes Public access on 10/10/2010' }
  end
end
