# frozen_string_literal: true

module SS
  # Some variables differ between the staging and production servers.  Both run in
  # the 'production' Rails environment, so we can't just test {Rails.env}
  PSQL_SECRET_ID = if Rails.application.config.host_name == "alexandria.ucsb.edu"
                     "1441"
                   else
                     "1443"
                   end

  # @param id [String, Integer] the secret ID
  # @param field [String] the field (Password, Username, etc.)
  def self.get_secret(id, field)
    Dir.chdir("/opt/secret-server") do
      `java -jar secretserver-jconsole.jar -s #{id} #{field}`.strip
    end
  rescue Errno::ENOENT
    # This just means we're in a dev/test environment where /opt/secret-server
    # doesn't exist
    ""
  end
end
