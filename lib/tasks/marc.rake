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

  desc "Download the MARC record for a PID"
  task :ark, [:pid] => :environment do |_, args|
    marc = SRU.by_ark(args[:pid])
    if marc
      File.open(
        File.join(Settings.marc_directory, "#{args[:pid]}.xml"), "w"
      ) do |f|
        f.write marc
      end
    else
      $stderr.puts "ERROR: nothing found for #{args[:pid]}"
    end
  end
end
