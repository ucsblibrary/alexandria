# frozen_string_literal: true

module Auth::YAML
  # @param user [String]
  # @param password [String]
  # @param type [String]
  #
  # @return [Boolean, Array] False if a failed authentication, otherwise an
  #     array of the user's groups
  def self.auth
    lambda do |user:, password:, type: "ucsb"|
      return false unless user

      login = login_as(type).select do |u|
        u["username"] == user
      end.first

      return false if login.nil?
      return false if login["password"] != password

      login["groups"].map { |group| "AdminPolicy::#{group}".constantize }
    end
  end

  def self.login_as(type)
    credential = case type
                 when "ucsb"
                   "campus_ldap.yml"
                 when "staff"
                   "active_directory.yml"
                 end

    @conf ||= YAML.safe_load(
      ERB.new(File.read(Rails.root.join("config", "credentials", credential))).result,
      # by default #safe_load doesn't allow aliases
      # https://github.com/ruby/psych/blob/2884f7bf8d1bd6433babe6b7b8e4b6007e59af97/lib/psych.rb#L290
      [], [], true
    )
  end
end
