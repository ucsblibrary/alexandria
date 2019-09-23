# frozen_string_literal: true

module Merritt
  def self.table_name_prefix
    "merritt_"
  end

  class Etd < ActiveRecord::Base
    def self.merritt_id(etd)
      "ark" + etd.entry_id.split("ark").last
    end

    def self.ark(etd)
      etd.entry_id.split("/").last
    end
  end
end
