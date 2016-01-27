require 'rails_helper'

describe Qa::TermsController do
  routes { Qa::Engine.routes }

  before do
    AdminPolicy.ensure_admin_policy_exists
  end

  describe 'license vocabulary' do
    it 'returns terms' do
      get :search, vocab: 'local', subauthority: 'license', q: 'ND'
      expect(response).to be_success
    end
  end

  describe 'sub_location vocabulary' do
    it 'returns terms' do
      get :search, vocab: 'local', subauthority: 'sub_location', q: 'ND'
      expect(response).to be_success
    end
  end

  describe 'work_type vocabulary' do
    it 'returns terms' do
      get :search, vocab: 'local', subauthority: 'work_type', q: 'image'
      expect(response).to be_success
      expect(response.body).to eq "[{\"id\":\"http://id.loc.gov/vocabulary/resourceTypes/img\",\"label\":\"Still image\"},{\"id\":\"http://id.loc.gov/vocabulary/resourceTypes/mov\",\"label\":\"Moving image\"}]"
    end
  end

  describe 'local names' do
    let!(:agent) { Agent.create(foaf_name: 'Frodo Baggins') }

    it 'returns terms' do
      get :search, vocab: 'local', subauthority: 'names', q: 'Baggins'
      expect(response).to be_success
      expect(response.body).to eq "[{\"id\":\"#{agent.uri}\",\"label\":\"Frodo Baggins\"}]"
    end
  end

  describe 'local subjects' do
    let!(:topic) { Topic.create(label: ['Frodo Baggins']) }
    let!(:person) { Person.create(foaf_name: 'Bilbo Baggins') }

    it 'returns (topic) Frodo but not (person) Bilbo' do
      get :search, vocab: 'local', subauthority: 'subjects', q: 'Baggins'
      expect(response).to be_success
      expect(response.body).to eq "[{\"id\":\"#{topic.uri}\",\"label\":\"Frodo Baggins\"}]"
    end
  end
end
