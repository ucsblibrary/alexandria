require 'rails_helper'

describe RecordsController do
  routes { HydraEditor::Engine.routes }
  let(:user) { create :admin }
  before do
    AdminPolicy.ensure_admin_policy_exists
    sign_in user
  end

  # Don't fetch external records (speed up)
  before { allow_any_instance_of(RDF::DeepIndexingService).to receive(:fetch_external) }

  describe '#update' do
    let(:image) { create(:image, creator_attributes: initial_creators) }

    context 'Adding new creators' do
      let(:initial_creators) { [{ id: 'http://id.loc.gov/authorities/names/n87914041' }] }
      let(:contributor_attributes) do
        { '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87914041',
                   'hidden_label' => 'http://id.loc.gov/authorities/names/n87914041' },
          '1' => { 'id' => 'http://id.loc.gov/authorities/names/n87141298',
                   'predicate' => 'creator',
                   'hidden_label' => 'http://dummynamespace.org/creator/' },
          '2' => { 'id' => '',
                   'hidden_label' => 'http://dummynamespace.org/creator/' },
                        }
      end

      it 'adds creators' do
        patch :update, id: image, image: { contributor_attributes: contributor_attributes }
        expect(image.reload.creator_ids).to eq ['http://id.loc.gov/authorities/names/n87914041',
                                                'http://id.loc.gov/authorities/names/n87141298']
      end
    end

    context 'removing a creator' do
      let(:initial_creators) do
        [{ id: 'http://id.loc.gov/authorities/names/n87914041' },
         { id: 'http://id.loc.gov/authorities/names/n81019162' }]
      end

      let(:contributor_attributes) do
        {
          '0' => { 'id' => 'http://id.loc.gov/authorities/names/n87914041', '_destroy' => '' },
          '1' => { 'id' => 'http://id.loc.gov/authorities/names/n81019162', predicate: 'creator', '_destroy' => 'true' },
          '2' => { 'id' => '', '_destroy' => '' },
        }
      end

      it 'removes creators' do
        patch :update, id: image, image: { contributor_attributes: contributor_attributes }
        expect(image.reload.creator_ids).to eq ['http://id.loc.gov/authorities/names/n87914041']
      end
    end

    context 'dates' do
      let(:ts_attributes) do
        {
          'start' => ['2014'],
          'start_qualifier' => [''],
          'finish' => [''],
          'finish_qualifier' => [''],
          'label' => [''],
          'note' => [''],
        }
      end

      let(:initial_creators) { [{ id: 'http://id.loc.gov/authorities/names/n87914041' }] }

      context 'created' do
        context 'creating a new date' do
          it 'persists the nested object' do
            patch :update, id: image, image: {
              created_attributes: { '0' => ts_attributes },
              creator_attributes: initial_creators,
            }

            image.reload

            created_date = image.created.first

            expect(image.created.count).to eq 1

            expect(created_date.start).to eq ['2014']
            expect(created_date).to be_persisted
          end
        end

        context 'when the created date already exists' do
          before do
            image.created.build(ts_attributes)
            image.created_will_change!
            image.save!
          end

          it 'allows deletion of the existing timespan' do
            image.reload
            expect(image.created.count).to eq 1

            patch :update, id: image, image: {
              creator_attribues: initial_creators,
              created_attributes: {
                '0' => { id: image.created.first.id, _destroy: 'true' }
              },
            }

            image.reload

            expect(image.created.count).to eq(0)
          end

          it 'allows updating the existing timespan' do
            patch :update, id: image, image: {
              created_attributes: {
                '0' => ts_attributes.merge(id: image.created.first.id, start: ['1337'], start_qualifier: ['approximate'])
              },
              creator_attributes: initial_creators,
            }

            image.reload

            expect(image.created.count).to eq(1)

            created_date = image.created.first

            expect(image.created.size).to eq 1
            expect(created_date.start).to eq ['1337']
            expect(created_date.start_qualifier).to eq ['approximate']
          end
        end
      end
    end # context dates
  end  # describe #update

  describe '#destroy' do
    routes { Rails.application.routes }

    describe 'a local authority record' do
      let!(:person) { create(:person) }

      context 'a person that is referenced by another record' do
        let!(:image) { create(:image, creator: [person]) }

        it 'returns message that record cannot be destroyed' do
          expect do
            delete :destroy, id: person
          end.to change { Person.count }.by(0)
          expect(flash[:alert]).to eq "Record \"#{person.rdf_label.first}\" cannot be deleted because it is referenced by 1 other record."
        end
      end

      context 'a person that is not referenced by any other record' do
        it 'destroys the record' do
          expect do
            delete :destroy, id: person
          end.to change { Person.count }.by(-1)
          expect(response).to redirect_to local_authorities_path
          expect(flash[:notice]).to eq "Record \"#{person.rdf_label.first}\" has been destroyed"
        end
      end

      context 'a non-admin user' do
        let(:user) { create :user }

        it 'access is denied' do
          delete :destroy, id: person
          expect(flash[:alert]).to match /You are not authorized/
          expect(response).to redirect_to root_path
        end
      end
    end
  end  # describe #destroy

  describe '#new_merge' do
    routes { Rails.application.routes }

    context 'for local authority records' do
      let!(:person) { create(:person, foaf_name: 'old name') }

      it 'displays the record merge form' do
        get :new_merge, id: person
        expect(assigns(:record)).to eq person
        expect(response).to be_successful
        expect(response).to render_template(:new_merge)
      end
    end

    context 'records that are not local authorities' do
      let(:image) { create(:image) }

      it 'returns message that record cannot be merged' do
        get :new_merge, id: image
        expect(flash[:alert]).to eq 'This record cannot be merged.  Only local authority records can be merged.'
        expect(response).to redirect_to local_authorities_path
      end
    end

    context 'a non-admin user' do
      let(:user) { create :user }
      let!(:person) { create(:person) }

      it 'access is denied' do
        get :new_merge, id: person
        expect(flash[:alert]).to match /You are not authorized/
        expect(response).to redirect_to root_path
      end
    end
  end  # describe #new_merge

  describe '#merge' do
    routes { Rails.application.routes }

    let!(:person) { create(:person) }
    let(:target_id) { '92208543-9840-4f8b-8e97-561ba46cfd6f' }
    let(:fedora_path) { ActiveFedora.config.credentials[:url] + ActiveFedora.config.credentials[:base_path] }
    let(:target_url) { "#{fedora_path}/92/20/85/43/#{target_id}" }

    let(:form_params) do
      # This is how it looks when the javascript adds the data to the form.
      { 'subject_merge_target_attributes' => { '0' => { 'hidden_label' => 'Topic 3', 'id' => target_url } } }
    end

    it 'queues a job to merge the records' do
      expect(MergeRecordsJob).to receive(:perform_later).with(person.id, target_id, user.user_key)
      post :merge, { id: person }.merge(form_params)
      expect(response).to redirect_to local_authorities_path
    end

    context 'missing arguments' do
      let(:form_params) do
        { 'subject_merge_target_attributes' => { '0' => { 'hidden_label' => '', 'id' => '' } } }
      end

      it 'displays an error message' do
        expect(MergeRecordsJob).to_not receive(:perform_later)
        post :merge, { id: person }.merge(form_params)
        expect(response).to render_template(:new_merge)
        expect(flash[:alert]).to match /Error:  Unable to queue merge job.  Please fill in all required fields./
      end
    end

    context 'a non-admin user' do
      let(:user) { create :user }

      it 'access is denied' do
        post :merge, { id: person }.merge(form_params)
        expect(flash[:alert]).to match /You are not authorized/
        expect(response).to redirect_to root_path
      end
    end
  end # describe #merge
end
