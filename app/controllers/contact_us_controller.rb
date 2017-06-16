# frozen_string_literal: true

# Sends email to the admin from the contact form
class ContactUsController < ApplicationController
  layout "curation_concerns"

  def new
    @page_title = "Contact Us"
  end

  # When a user submits the "Contact Us" form, send the email.
  def create
    ContactUsMailer.web_inquiry(
      params.permit(:name, :email, :category, :message, :zipcode)
    ).deliver_now

    flash[:notice] = "Thank you for the feedback.  "\
                     "Your submission has been successfully sent."
    redirect_to :back
  end
end
