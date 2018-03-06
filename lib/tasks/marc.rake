# frozen_string_literal: true

require "httpclient"
require "sru"

namespace :marc do
  desc "Download Wax Cylinder MARC records from SRU"
  task download_cylinders: :environment do
    SRU.download_all(:cylinder)
  end

  desc "Download ETD MARC records from SRU"
  task download_etds: :environment do
    SRU.download_all(:etd)
  end

  desc "Download the MARC record for an ARK (e.g., '48907/f3cv4hxn')"
  task :ark, [:pid] => :environment do |_, args|
    marc = SRU.by_ark(args[:pid])
    output = File.join(Settings.marc_directory,
                       "#{args[:pid].split("/").last}.xml")

    return warn "ERROR: nothing found for #{args[:pid]}" if marc.nil?

    File.open(output, "w") do |f|
      f.write marc
    end
  end
end
