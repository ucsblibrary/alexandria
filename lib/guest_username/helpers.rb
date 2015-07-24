module GuestUsername
  module Helpers
    def self.define_helpers(mapping) #:nodoc:
      class_name = mapping.class_name
      mapping = mapping.name

      class_eval <<-METHODS, __FILE__, __LINE__ + 1
        def guest_username_authentication_key key
          key &&= nil unless key.to_s.match(/^guest/)
          key ||= "guest_" + guest_#{mapping}_unique_suffix
        end
      METHODS
    end
  end
end
