require 'rails_helper'

describe LocalAuthoritiesController do
  let(:person) { create(:person) }
  let(:group) { create(:group) }
  let(:org) { create(:org) }
  let(:agent) { create(:agent) }
  let(:topic) { Topic.create!(label: ['A Local Subject']) }

  describe 'a regular user' do
    let(:user) { create :user }
    before { sign_in user }

    describe 'get index' do
      before { get :index }

      it 'access is denied' do
        expect(flash[:alert]).to match /You are not authorized/
        expect(response).to redirect_to root_path
      end
    end
  end


  describe 'logged in as admin user' do
    let(:admin) { create :admin }
    before { sign_in admin }

    describe 'get index' do
      let(:image) { create(:public_image) }

      before do
        ActiveFedora::Cleaner.clean!
        AdminPolicy.ensure_admin_policy_exists
        [person, group, org, agent, image, topic] # create the objects
        get :index
      end

      it 'only shows the models for local authorities' do
        doc_ids = assigns[:document_list].map(&:id)
        expect(doc_ids).to     include(person.id)
        expect(doc_ids).to     include(group.id)
        expect(doc_ids).to     include(org.id)
        expect(doc_ids).to     include(agent.id)
        expect(doc_ids).to_not include(image.id)
        expect(doc_ids).to     include(topic.id)
      end
    end

  end  # logged in as admin

end
