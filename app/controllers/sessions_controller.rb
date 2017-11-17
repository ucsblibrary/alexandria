# frozen_string_literal: true

class SessionsController < ApplicationController
  layout "curation_concerns"

  def new
    @page_title = "Log in"
  end

  def destroy
    log_out
    begin
      redirect_back(fallback_location: main_app.root_path)
    rescue ActionController::RedirectBackError
      redirect_to root_url
    end
  end

  def create
    type = params[:session][:type]

    username = if type == "ucsb"
                 params[:session][:user]
               else
                 # Active Directory always uses @library.ucsb.edu, so
                 # convert adunn and adunn@ucsb.edu to
                 # adunn@library.ucsb.edu
                 params[:session][:user].sub(/@(library\.)?ucsb\.edu/, "") +
                   "@library.ucsb.edu"
               end

    groups = Rails.application.config.auth_method.call(
      user: username,
      password: params[:session][:password],
      type: type
    )

    if groups
      user = User.find_or_create_by(username: username)
      update_groups_for!(user, groups, type)

      log_in(username)
      return redirect_to root_url
    else
      flash.now[:error] = "Bad email/password combination."
      return render "new"
    end
  end
end
