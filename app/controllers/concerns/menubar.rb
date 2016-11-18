module Menubar
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
