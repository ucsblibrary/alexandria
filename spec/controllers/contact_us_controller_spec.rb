require 'rails_helper'

RSpec.describe ContactUsController, type: :controller do
  let(:frodo) { 'Frodo Baggins' }
  let(:frodo_email) { 'frodo@example.com' }
  let(:from) { 'Frodo Baggins <frodo@example.com>' }

  let(:category) { 'Feedback' }
  let(:subject) { '[ADRL Demo] Feedback' }
  let(:spam_subject) { '[ADRL Demo SPAMBOT?] Feedback' }

  let(:message) { 'Hello there, friends.' }
  let(:referer) { 'Page that I came from' }

  before do
    request.env['HTTP_REFERER'] = referer
    ActionMailer::Base.deliveries.clear
  end

  describe 'GET new' do
    before { get :new }

    it 'displays the "contact us" form' do
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end
  end

  describe 'GET create' do
    before do
      post :create, name: frodo, email: frodo_email, category: category, message: message
    end

    it 'generates an email' do
      expect(response).to redirect_to referer
      expect(flash[:notice]).to match(/Thank you for the feedback/i)
      expect(ActionMailer::Base.deliveries.count).to eq 1
      email = ActionMailer::Base.deliveries.first

      expect(email.to).to eq Array(Rails.application.secrets.contact_us_email_to)
      expect(email.to_s).to match(from)
      expect(email.from).to eq Array(frodo_email)
      expect(email.body.to_s).to eq message
      expect(email.subject).to eq subject
    end
  end

  describe 'GET create with spam' do
    before do
      # If the invisible zipcode field is filled in,
      # we suspect it is spam.
      post :create, name: frodo, email: frodo_email, category: category, message: message, zipcode: '55402'
    end

    it 'generates an email, but flags it as spam' do
      expect(ActionMailer::Base.deliveries.count).to eq 1
      email = ActionMailer::Base.deliveries.first
      expect(email.subject).to eq spam_subject
    end
  end
end
