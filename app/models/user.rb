class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User

  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :registerable, :rememberable, :trackable

  serialize :group_list, Array

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
  end

  # Groups that user is a member of. Cached locally for 1 day
  def groups
    cached_groups do
      fetch_groups!
    end
  end

  # get the groups from LDAP and update the local cache
  def fetch_groups!
    new_groups = ldap_groups.map do |dn|
      /^cn=([^,]+),/.match(dn)[1]
    end
  end

  private

    def cached_groups(&block)
      update(group_list: yield, groups_list_expires_at: 1.day.from_now) if groups_need_update?
      group_list
    end

    def groups_need_update?
      groups_list_expires_at.blank? || groups_list_expires_at < Time.now
    end

end
