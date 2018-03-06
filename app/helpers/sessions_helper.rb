# frozen_string_literal: true

module SessionsHelper
  def log_in(user)
    reset_session
    session[:user] = user
  end

  def current_user
    @current_user ||= User.find_by(username: session[:user]) if session[:user]
  end

  def logged_in?
    current_user
  end

  def log_out
    session.delete(:user)
    @current_user = nil
    reset_session
  end

  # @param [User] user
  # @param [Array] groups
  # @param [type] string
  def update_groups_for!(user, groups, type)
    default_groups = [AdminPolicy::UCSB_GROUP]
    special_groups = case type
                     when "staff"
                       [AdminPolicy::META_ADMIN, AdminPolicy::RIGHTS_ADMIN]
                     when "ucsb"
                       []
                     end

    new_groups = special_groups.select do |sg|
      groups.include? sg
    end

    user.update(group_list: new_groups + default_groups)
  end
end
