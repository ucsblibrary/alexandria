require 'rails_helper'

RSpec.describe ContactUsMailer, type: :mailer do
  let(:from) { 'frodo@example.com' }
  let(:body) { 'The message' }
  let(:subj) { 'There and Back Again' }
  let(:subj_with_header) { '[ADRL Demo] There and Back Again' }
  let(:spam_subj) { '[ADRL Demo SPAMBOT?] There and Back Again' }

  describe '#web_inquiry' do
    before do
      email
    end

    describe 'happy path' do
      subject(:email) do
        msg = ContactUsMailer.web_inquiry(from, subj, body)
        msg.deliver_now
      end

      it 'generates an email with info from the form' do
        expect(ActionMailer::Base.deliveries).to_not be_empty
        expect(email.to).to eq Array(Rails.application.secrets.contact_us_email_to)
        expect(email.from).to eq Array(from)
        expect(email.subject).to eq subj_with_header
        expect(email.body.to_s).to eq body
      end
    end

    describe 'with a suspected spam message' do
      subject(:email) do
        msg = ContactUsMailer.web_inquiry(from, subj, body, true)
        msg.deliver_now
      end

      it 'the generated email has a special subject line' do
        expect(email.subject).to eq spam_subj
      end
    end
  end
end
