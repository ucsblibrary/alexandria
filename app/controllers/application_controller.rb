# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper Openseadragon::OpenseadragonHelper
  include Menubar

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include CurationConcerns::ApplicationControllerBehavior

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
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

  rescue_from Blacklight::Exceptions::RecordNotFound do |e|
    logger.error "(Blacklight::Exceptions::RecordNotFound): #{e.inspect}"
    @unknown_type = "Document"
    @unknown_id = params[:id]
    render "errors/not_found", status: 404
  end

  rescue_from Blacklight::Exceptions::InvalidSolrID do |e|
    logger.error e
    @unknown_type = "Document"
    @unknown_id = params[:id]
    render "errors/not_found", status: 404
  end

  def on_campus?
    return false unless request.remote_ip
    on_campus_network_prefixes.any? { |prefix| request.remote_ip.start_with?(prefix) }
  end
  helper_method :on_campus?

  def on_campus_network_prefixes
    ["128.111", "169.231"]
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, on_campus?)
  end

  def show_contributors?(_config, document)
    !document.etd?
  end

  def show_author?(_config, document)
    document.etd?
  end
end
