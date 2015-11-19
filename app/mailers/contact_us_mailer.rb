class ContactUsMailer < ApplicationMailer
  default to: Rails.application.secrets.contact_us_email_to

  def web_inquiry(from, subj, body, spam = false)
    mail(from: from,
         subject: subject_header(spam) + subj,
         body: body)
  end

  # The "Contact Us" form contains a Zip Code field as a
  # honeypot for spam bots.  If that field is filled in,
  # we suspect this email might be a spam message and flag it
  # with a special subject header.
  def subject_header(spam = false)
    header = Rails.env.production? ? 'ADRL' : 'ADRL Demo'
    spam_marker = spam ? ' SPAMBOT?' : ''
    "[#{header}#{spam_marker}] "
  end
end
