# frozen_string_literal: true

module Merritt
  def self.table_name_prefix
    "merritt_"
  end

  class Feed < ActiveRecord::Base
    def self.create_feed(page, last_modified)
      create!(
        page: page.to_i,
        last_modified: last_modified.to_datetime
      )
    end
  end
end
