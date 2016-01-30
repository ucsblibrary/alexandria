require 'rails_helper'

describe Image do
  it 'has a title' do
    subject.title = ['War and Peace']
    expect(subject.title).to eq ['War and Peace']
  end

  it 'has collections' do
    expect(subject.in_collections).to eq []
  end

  it 'can have an embargo' do
    expect(subject.respond_to?(:embargo_release_date)).to be true
    expect(subject.enforce_future_date_for_embargo?).to be false
  end

  describe 'nested attributes' do
    context 'for creator' do
      it 'should ignore empty ids' do
        subject.creator_attributes = { '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87141298' },
                                       '1' => { 'id' => '' } }
        expect(subject.creator.size).to eq 1
      end
    end

    context 'for landscape_architect' do
      it 'should ignore empty ids' do
        subject.landscape_architect_attributes = { '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87141298' },
                                                   '1' => { 'id' => '' } }
        expect(subject.landscape_architect.size).to eq 1
      end
    end

    context 'for performer' do
      it 'should ignore empty ids' do
        subject.performer_attributes = { '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87141298' },
                                         '1' => { 'id' => '' } }
        expect(subject.performer.size).to eq 1
      end
    end

    context 'for location' do
      it 'should ignore empty ids' do
        subject.location_attributes = { '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87141298' },
                                        '1' => { 'id' => '' } }
        expect(subject.location.size).to eq 1
      end
    end

    context 'for lc_subject' do
      it 'should ignore empty ids' do
        subject.lc_subject_attributes = { '0' => { 'id' => 'http://id.loc.gov/authorities/subjects/sh85111007' },
                                          '1' => { 'id' => '' } }
        expect(subject.lc_subject.size).to eq 1
      end
    end

    context 'for form_of_work' do
      it 'should ignore empty ids' do
        subject.form_of_work_attributes = { '0' => { 'id' => 'http://vocab.getty.edu/aat/300026816' },
                                            '1' => { 'id' => '' } }
        expect(subject.form_of_work.size).to eq 1
      end
    end

    context 'for date created' do
      before { subject.title = ['Test title'] }

      it 'allows blank ids' do
        subject.save!
        subject.reload

        subject.attributes = {
          created_attributes: {
            '0' => {
              start: ['2014']
            }
          }
        }

        subject.save!
        expect(subject.reload.created.size).to eq(1)
        expect(subject).to be_valid
      end
    end

    context 'for notes' do
      before do
        subject.title = ['Test title']
        subject.notes_attributes = [{ value: 'Title from item.' }, { value: "Postcard caption: 25. Light-House Tower Sta. Barbara Earth Quake.\n6-29-25." }, { value: "[Identification of Item], Santa Barbara picture\npostcards collection. SBHC Mss 36. Department of Special Collections, UC Santa Barbara\nLibrary, University of California, Santa Barbara.", note_type: 'preferred citation' }]
      end

      it 'has notes' do
        subject.save!
        subject.reload
        expect(subject.notes.size).to eq 3
      end
    end

    describe 'dates' do
      context 'created' do
        before do
          subject.created_attributes = [{ start: ['1940'], finish: ['1959'] }]
        end
        it 'has date_created' do
          expect(subject.created.first.start).to eq ['1940']
          expect(subject.created.first.finish).to eq ['1959']
        end
      end
    end
  end

  describe '#to_solr' do
    let(:image) { Image.new }
    it 'calls the ImageIndexer' do
      expect_any_instance_of(ImageIndexer).to receive(:generate_solr_document).and_return({})
      image.to_solr
    end

    describe "human_readable_type" do
      subject { image.to_solr[Solrizer.solr_name('human_readable_type', :facetable)] }
      it { is_expected.to eq 'Image' }
    end
  end

  describe 'dates' do
    let(:image) { build(:image) }

    describe 'ranges' do
      before do
        image.created.build(start: ['1911'], finish: ['1912'])
        image.issued.build(start: ['1913'], finish: ['1917'])
      end

      it 'stores them' do
        expect(image.created.first.start).to eq ['1911']
        expect(image.created.first.finish).to eq ['1912']
        expect(image.issued.first.start).to eq ['1913']
        expect(image.issued.first.finish).to eq ['1917']
      end

      context "when loading from fedora" do
        before do
          image.save!
          image.reload
        end

        it 'loads them' do
          expect(image.issued.first.start).to eq ['1913']
        end
      end
    end

    describe 'points' do
      before do
        image.issued.build(start: ['1913'])
      end
      it 'stores them' do
        expect(image.issued.first.start).to eq ['1913']
      end
    end
  end

  describe 'lc_subject' do
    context "with a literal value" do
      let(:image) { Image.new(lc_subject: ['foo']) }
      it "isn't valid" do
        expect(image).not_to be_valid
        expect(image.errors[:base]).to eq ["`foo' for `lc_subject' property is expected to be a URI, but it is a String"]
      end
    end

    context "with a local vocabulary" do
      before do
        AdminPolicy.ensure_admin_policy_exists
        subject.title = ['Test title']
      end

      let(:topic) { Topic.create(label: ['Birds of California']) }

      it 'allows local vocabularies' do
        subject.lc_subject = [topic]
        expect(subject).to be_valid
      end
    end
  end

  describe 'work_type' do
    context "with a literal value" do
      let(:image) { Image.new(work_type: ['foo']) }

      it "isn't valid" do
        expect(image).not_to be_valid
        expect(image.errors[:base]).to eq ["`foo' for `work_type' property is expected to be a URI, but it is a String"]
      end
    end
  end

  describe '#[]' do
    context 'with a local creator' do
      let(:person) { Person.create(foaf_name: 'Tony') }
      let(:tony_uri) { RDF::URI.new(person.uri) }
      let(:merle_uri) { RDF::URI.new('http://id.loc.gov/authorities/names/n81053687') }
      let(:photographers) { [tony_uri, merle_uri] }

      let(:image) { Image.new(photographer: photographers) }

      subject { image[:photographer] }
      it 'has an ActiveFedora object and and ActiveTriples object' do
        expect(subject.first).to eq person
        expect(subject.last).to be_kind_of ActiveTriples::Resource
      end
    end
  end

  describe '#to_partial_path' do
    subject { described_class.new.to_partial_path }
    it { is_expected.to eq 'catalog/document' }
  end
end
