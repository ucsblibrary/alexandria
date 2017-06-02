# frozen_string_literal: true

module SessionsHelper
  def log_in(user)
    reset_session
    session[:user] = user
  end

  def current_user
    @current_user ||= User.find_by(username: session[:user]) if session[:user]
  end

  def logged_in?
    current_user
  end

  def log_out
    session.delete(:user)
    @current_user = nil
    reset_session
  end

  def ldap_conf
    @conf ||= YAML.safe_load(
      ERB.new(File.read("#{Rails.root}/config/ldap.yml")).result,
      # by default #safe_load doesn't allow aliases
      # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
      [], [], true
    )
  end

  def makeopts(conf)
    opts = {
      host: conf["host"],
      port: conf["port"],
      auth: {
        method: :simple,
        username: conf["admin_user"],
        password: conf["admin_pass"],
      },
    }
    opts[:encryption] = { method: :simple_tls } if conf["ssl"]
    opts
  end

  def auth_with_ldap(options = {})
    user = options.fetch(:user, nil)
    password = options.fetch(:password, "")
    type = options.fetch(:type, "ucsb")
    return false unless user

    conf = ldap_conf[type][Rails.env]
    connection = Net::LDAP.new(makeopts(conf))

    return false unless connection.bind

    connection.bind_as(password: password,
                       filter: "(#{conf["filter"]}=#{user})",
                       base: conf["group_base"])
  end

  # @param [User] user
  # @param [Array] groups
  # @param [type] string
  def update_groups_for!(user, groups, type)
    return if groups.first[:memberof].empty?

    default_groups = [AdminPolicy::UCSB_GROUP]

    special_groups = case type
                     when "staff"
                       [AdminPolicy::META_ADMIN, AdminPolicy::RIGHTS_ADMIN]
                     when "ucsb"
                       []
                     end

    ldap_groups = if Rails.env.production?
                    groups.first[:memberof].map { |m| m.split(",").first.sub(/^CN=/, "") }
                  else
                    default_groups + special_groups
                  end

    user.update_attributes(
      :group_list,
      default_groups + (special_groups.select { |grp| ldap_groups.include? grp })
    )
  end
end
