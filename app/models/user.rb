# frozen_string_literal: true

class User < ActiveRecord::Base
  include Hydra::User
  include Hyrax::User
  include Blacklight::User

  serialize :group_list, Array

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
  end

  # Override so hydra-access-controls doesn't smuggle in its
  # undeclared Devise dependency:
  # https://github.com/projecthydra/hydra-head/blob/429d173df66c33d12859d9c0d7c6c1993f790b0e/hydra-access-controls/lib/hydra/user.rb#L17-L19
  def self.find_by_user_key(key)
    find_by(username: key)
  end

  # Overriding blacklight-access_controls
  # https://github.com/projectblacklight/blacklight-access_controls/blob/c027f0cc0ee6f6cc30f9dd84076d36cbcee238fe/lib/blacklight/access_controls/user.rb#L18-L20
  def user_key
    username
  end

  # Groups that user is a member of.
  def groups
    group_list
  end

  def ucsb_user?
    groups.include? AdminPolicy::UCSB_GROUP
  end

  # CC FileSetActors need to be associated with a Rails user for some
  # reason
  def self.batchuser
    User.find_or_create_by(username: "batchuser")
  end
end
