module Menubar
  extend ActiveSupport::Concern

  included do
    helper_method :embargo_manager?
    helper_method :can_read_authorities?
  end

  def embargo_manager?
    can?(:discover, Hydra::AccessControls::Embargo)
  end

  def can_read_authorities?
    can?(:read, :local_authorities)
  end

  def can_destroy_authorities?
    can?(:destroy, :local_authorities)
  end

end
