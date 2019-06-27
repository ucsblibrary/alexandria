# frozen_string_literal: true

require "csv"

require "csv"

namespace :import do
  desc "Import merritt arks from csv for UCSB ETDs"

  task :merritt_arks, [:file_path] => :environment do |_t, args|
    puts "Beginning Import #{Time.zone.now}"
    missing_etds = []
    # CSV file contents would be as below
    # proquest,merritt,ucsb
    # ProQuestID:0035D,ark:/13030/m00999g9,ark:/48907/f30865g5
    CSV.foreach(args[:file_path], headers: true) do |row|
      ucsb_ark = row["ucsb"].split("/").last
      merritt_ark = row["merritt"]
      begin
        etd = ETD.find ucsb_ark
        next if etd.merritt_id.present?
        etd.merritt_id = [merritt_ark]
        etd.save
        puts "Updated UCSB ETD: #{ucsb_ark}"
      rescue ActiveFedora::ObjectNotFoundError
        missing_etds << ucsb_ark
      end
    end
    puts "Missing ETDs: #{missing_etds.inspect}" if missing_etds.present?
    puts "Import Complete #{Time.zone.now}"
  end
end
