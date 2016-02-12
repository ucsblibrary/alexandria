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
        expect(flash[:alert]).to match(/You are not authorized/)
        expect(response).to redirect_to root_path
      end
    end
  end

  describe 'logged in as admin user' do
    let(:admin) { create :admin }
    before { sign_in admin }

    describe 'get index' do
      before do
        ActiveFedora::Cleaner.clean!
        AdminPolicy.ensure_admin_policy_exists
      end

      let!(:image) { create(:public_image) }
      let!(:person) { create(:person) }
      let!(:group) { create(:group) }
      let!(:org) { create(:org) }
      let!(:agent) { create(:agent) }
      let!(:topic) { Topic.create!(label: ['A Local Subject']) }

      it 'only shows the models for local authorities' do
        get :index
        doc_ids = assigns[:document_list].map(&:id)
        expect(doc_ids).to include(person.id)
        expect(doc_ids).to include(group.id)
        expect(doc_ids).to include(org.id)
        expect(doc_ids).to include(agent.id)
        expect(doc_ids).to_not include(image.id)
        expect(doc_ids).to include(topic.id)
      end
    end
  end # logged in as admin

  describe '#show_delete_link?' do
    let(:doc) { SolrDocument.new('has_model_ssim' => 'Person') }
    subject { controller.send(:show_delete_link?, nil, document: doc) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'for an admin user' do
      let(:user) { create :admin }
      it { is_expected.to be true }
    end

    context 'for a non-admin user' do
      let(:user) { create :user }
      it { is_expected.to be false }
    end
  end

  describe '#show_merge_link?' do
    let(:doc) { SolrDocument.new('has_model_ssim' => 'Person') }
    subject { controller.send(:show_merge_link?, nil, document: doc) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'for a non-admin user' do
      let(:user) { create :user }
      it { is_expected.to be false }
    end

    context 'for an admin user' do
      let(:user) { create :admin }
      it { is_expected.to be true }
    end
  end
end
