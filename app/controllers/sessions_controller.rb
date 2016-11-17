# frozen_string_literal: true

class SessionsController < ApplicationController
  layout "curation_concerns"

  def new
    @page_title = "Log in"
  end

  def destroy
    log_out
    begin
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to root_url
    end
  end

  def create
    type = params[:session][:type]
    username = params[:session][:user]

    # Active Directory always uses @library.ucsb.edu
    if type == "staff"
      username = "#{username.sub(/@(library\.)?ucsb\.edu/, "")}@library.ucsb.edu"
    end

    groups = auth_with_ldap(
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
      return render type
    end
  end
end
