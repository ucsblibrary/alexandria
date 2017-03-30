# frozen_string_literal: true

class AuthService
  def initialize(controller)
    @ability = controller.current_ability
    @params  = controller.params
  end

  def can?(_action, object)
    # Strip off the /files/fedora-junk to get the FileSet PID
    id = object.id.sub(%r{\/.*}, "")
    return true if @ability.test_discover_from_policy(id)
    @params["size"].to_i <= 400
  end
end
