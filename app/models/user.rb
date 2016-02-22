class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Curation Concerns behaviors.
  include CurationConcerns::User


  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  include CurationConcerns::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :rememberable, :trackable

  serialize :group_list, Array

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
  end

  # Groups that user is a member of. Cached locally for 1 day
  def groups
    return [] if new_record?
    cached_groups do
      fetch_groups!
    end
  end

  # get the groups from LDAP and update the local cache
  def fetch_groups!
    new_groups = ldap_groups.map do |dn|
      /^cn=([^,]+),/.match(dn)[1]
    end

    # TODO:  In the future when we switch to Shibboleth for
    # login, we will need to code some way to distinguish
    # between a UCSB user and a UC user from a different campus.
    # For now, we will assume that anyone who logs in with LDAP
    # is a UCSB user.
    new_groups += [AdminPolicy::UCSB_GROUP] if ucsb_user?
  end

  def ucsb_user?
    !new_record?
  end

  def self.batchuser
    User.find_by_user_key(batchuser_key) || User.create!(Devise.authentication_keys.first => batchuser_key)
  end

  def self.batchuser_key
    'batchuser'
  end

  private

    def cached_groups(&_block)
      update(group_list: yield, groups_list_expires_at: 1.day.from_now) if groups_need_update?
      group_list
    end

    def groups_need_update?
      groups_list_expires_at.blank? || groups_list_expires_at < Time.now
    end
end
