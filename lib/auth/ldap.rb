# frozen_string_literal: true

module Auth::LDAP
  # @param user [String]
  # @param password [String]
  # @param type [String]
  #
  # @return [Boolean, Array] False if a failed authentication, otherwise an
  #     array of the user's groups
  def self.auth
    lambda do |user:, password:, type: "ucsb"|
      return false unless user

      conf = ldap_conf[type][Rails.env]
      connection = Net::LDAP.new(makeopts(conf))

      return false unless connection.bind

      groups = connection.bind_as(
        password: password,
        filter: "(#{conf["filter"]}=#{user})",
        base: conf["group_base"]
      )
      return false unless groups

      groups.first[:memberof].map do |m|
        m.split(",").first.sub(/^CN=/, "")
      end
    end
  end

  def self.ldap_conf
    @conf ||= YAML.safe_load(
      ERB.new(File.read(Rails.root.join("config", "ldap.yml"))).result,
      # by default #safe_load doesn't allow aliases
      # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
      [], [], true
    )
  end

  def self.makeopts(conf)
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
end
