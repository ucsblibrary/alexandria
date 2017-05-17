# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  include SessionsHelper

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include CurationConcerns::ApplicationControllerBehavior

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from Net::LDAP::BindingInformationInvalidError do |exception|
    render text: exception, status: 500
  end

  # https://github.library.ucsb.edu/ADRL/alexandria/issues/22
  rescue_from ActionController::InvalidAuthenticityToken do |e|
    logger.error e
    if params[:redirect]
      redirect_to params[:redirect]
    else
      redirect_to :back
    end
  end

  def on_campus?
    return true if Rails.env.development?

    return false unless request.remote_ip
    on_campus_network_prefixes.any? { |prefix| request.remote_ip.start_with?(prefix) }
  end
  helper_method :on_campus?

  def on_campus_network_prefixes
    %w[
      128.111
      169.231
    ]
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, on_campus?)
  end

  def deny_access(exception)
    if logged_in?
      begin
        redirect_to :back, alert: exception.message
      rescue ActionController::RedirectBackError
        redirect_to main_app.root_path
      end
    else
      redirect_to main_app.new_user_session_path, alert: exception.message
    end
  end

  def show_contributors?(_config, document)
    !document.etd?
  end

  def show_author?(_config, document)
    document.etd?
  end
end
