class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render text: exception, status: 500
  end

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior
  include CurationConcerns::ApplicationControllerBehavior
  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def on_campus?
    return false unless request.remote_ip
    on_campus_network_prefixes.any? { |prefix| request.remote_ip.start_with?(prefix) }
  end
  helper_method :on_campus?

  def on_campus_network_prefixes
    ['128.111', '169.231']
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, on_campus?)
  end

  # Should we display the admin menu?
  def admin_menu?
    can?(:discover, Hydra::AccessControls::Embargo) || can?(:destroy, :local_authorities)
  end
end
