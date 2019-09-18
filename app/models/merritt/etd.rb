# frozen_string_literal: true

module Merritt
  def self.table_name_prefix
    "merritt_"
  end

  class Etd < ActiveRecord::Base
    def self.merritt_id(etd)
      "ark" + etd.entry_id.split("ark").last
    end

    def self.create_etd(etd)
      create!(
        merritt_id:     merritt_id(etd),
        last_modified:  etd.last_modified.to_datetime
      )
    end
  end
end
