# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContactUsMailer, type: :mailer do
  let(:from) { "frodo@example.com" }
  let(:body) { "The message" }
  let(:subj) { "There and Back Again" }
  let(:zipcode) { nil }

  let(:params) do
    {
      email: from,
      category: subj,
      message: body,
      zipcode: zipcode,
    }
  end

  describe "#web_inquiry" do
    before do
      email
    end

    describe "happy path" do
      subject(:email) do
        msg = ContactUsMailer.web_inquiry(params)
        msg.deliver_now
      end

      it "generates an email with info from the form" do
        expect(ActionMailer::Base.deliveries).not_to be_empty
        expect(email.to).to(
          eq Array(Rails.application.secrets.contact_us_email_to)
        )
        expect(email.from).to eq Array(from)
        expect(email.subject).to eq "[ADRL Demo] There and Back Again"
        expect(email.body.to_s).to eq body
      end
    end

    describe "with a suspected spam message" do
      subject(:email) do
        msg = ContactUsMailer.web_inquiry(params)
        msg.deliver_now
      end

      let(:zipcode) { "93106" }

      it "the generated email has a special subject line" do
        expect(email.subject).to eq "[ADRL Demo SPAMBOT?] There and Back Again"
      end
    end
  end
end
