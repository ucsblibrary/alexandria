require 'rails_helper'

describe MergeRecordsService do
  let(:image1) { create(:image, id: 'image1', creator: [old_name], lc_subject: [old_name]) }
  let(:image2) { create(:image, id: 'image2', photographer: [old_name], lc_subject: [old_name, new_name, other_name]) }

  let(:collection) { create(:collection, collector: [old_name, other_name]) }

  let(:old_name) { create(:person, foaf_name: 'Old Name') }
  let(:new_name) { create(:person, foaf_name: 'New Name') }
  let(:other_name) { create(:person, foaf_name: 'Some Other Name') }



  describe '#initialize' do
    context 'normal init with no errors' do
      subject { described_class.new(old_name, new_name) }

      it 'sets instance variables' do
        expect(subject.old_reference).to eq old_name
        expect(subject.new_reference).to eq new_name
      end
    end

    context 'with non-local-authority records' do
      it 'raises an error' do
        expect {
          described_class.new(old_name, image1)
        }.to raise_error(IncompatibleMergeError, 'Error: Cannot merge records that are not local authority records.')
      end
    end

    context 'with incompatible merge target' do
      let(:topic) { Topic.create }

      it 'raises an error' do
        expect {
          described_class.new(old_name, topic)
        }.to raise_error(IncompatibleMergeError, 'Error: Cannot merge records that are not the same type of local authority.')
      end
    end

    context 'attempt to merge record with itself' do
      it 'raises an error' do
        expect { described_class.new(old_name, old_name) }.to raise_error(IncompatibleMergeError, 'Error: Cannot merge a record with itself.')
      end
    end
  end


  describe '#run' do
    subject { described_class.new(old_name, new_name) }

    before do
      [old_name, new_name, image1, image2, collection] # create the records
      old_name.reload
      subject.run
      image1.reload
      image2.reload
      collection.reload
    end

    it 'updates all references to the old name' do
      expect(image1.creator.count).to eq 1
      expect(image1.creator.first).to be_a(Oargun::ControlledVocabularies::Creator)
      expect(image1.creator.first.rdf_subject).to eq new_name.rdf_subject

      expect(image1.lc_subject.count).to eq 1
      expect(image1.lc_subject.first).to be_a(Oargun::ControlledVocabularies::Subject)
      expect(image1.lc_subject.first.rdf_subject).to eq new_name.rdf_subject

      expect(image2.photographer.count).to eq 1
      expect(image2.photographer.first).to be_a(Oargun::ControlledVocabularies::Creator)
      expect(image2.photographer.first.rdf_subject).to eq new_name.rdf_subject

      # It keeps other values and doesn't make duplicate values
      expect(image2.lc_subject.count).to eq 2
      expect(image2.lc_subject.map(&:class).uniq).to eq [Oargun::ControlledVocabularies::Subject]
      expect(image2.lc_subject.map(&:rdf_subject).sort).to eq [other_name.rdf_subject, new_name.rdf_subject].sort

      expect(collection.collector.count).to eq 2
      expect(collection.collector.map(&:class).uniq).to eq [Oargun::ControlledVocabularies::Creator]
      expect(collection.collector.map(&:rdf_subject).sort).to eq [other_name.rdf_subject, new_name.rdf_subject].sort

      # It deletes the old name
      expect(ActiveFedora::Base.exists?(old_name.id)).to be false
    end

    context 'with bad arguments' do
      before do
        [old_name, new_name] # create the records
        new_name.destroy     # merge target does not exist
      end

      it 'raises an error' do
        expect { subject.run }.to raise_error(Ldp::Gone)
      end
    end
  end  # describe #run

end
