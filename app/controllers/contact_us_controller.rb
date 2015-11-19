class ContactUsController < ApplicationController
  # Display the "Contact Us" form the the user.
  def new
  end

  # When a user submits the "Contact Us" form, send the email.
  def create
    from = %("#{params[:name]}" <#{params[:email]}>)
    spam = !params[:zipcode].blank?
    email = ContactUsMailer.web_inquiry(from, params[:category], params[:message], spam)
    email.deliver_now

    flash[:notice] = 'Thank you for the feedback.  Your submission has been successfully sent to the ADRL.'
    redirect_to :back
  end
end
