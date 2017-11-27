# frozen_string_literal: true

# This initializer is for variables that differ between the staging and
# production servers.  Both run in the 'production' Rails environment, so we
# can't just test {Rails.env}
PSQL_SECRET_ID = if Rails.application.config.host_name == "alexandria.ucsb.edu"
                   "1441"
                 else
                   "1443"
                 end
