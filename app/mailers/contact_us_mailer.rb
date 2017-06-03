# frozen_string_literal: true

class ContactUsMailer < ApplicationMailer
  default to: Rails.application.secrets.contact_us_email_to

  # @param [ActionController::Parameters] whitelisted
  def web_inquiry(whitelisted)
    mail(
      from: %("#{whitelisted[:name]}" <#{whitelisted[:email]}>),
      subject: (subject_header(spam: whitelisted[:zipcode].present?) +
                whitelisted[:category]),
      body: whitelisted[:message]
    )
  end

  # The "Contact Us" form contains a Zip Code field as a
  # honeypot for spam bots.  If that field is filled in,
  # we suspect this email might be a spam message and flag it
  # with a special subject header.
  #
  # @param [Boolean] spam
  # @return [String]
  def subject_header(spam: false)
    header = Rails.env.production? ? "ADRL" : "ADRL Demo"
    spam_marker = spam ? " SPAMBOT?" : ""
    "[#{header}#{spam_marker}] "
  end
end
