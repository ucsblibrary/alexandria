# frozen_string_literal: true

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

  task :adrl_arks, [:file_path] => :environment do |_t, args|
    puts "Beginning import #{Time.zone.now}"
    csv = CSV.read(args[:file_path], headers: true)
    count = 0
    missing_files = non_adrl = []

    CSV.open("tmp/adrl_arks.csv",
             "w",
             write_headers: true,
             headers: %w[proquest merritt ucsb]) do |row|
      ETD.all.each do |etd|
        # skip rows with ADRL arks
        next if csv.find { |rw| rw["ucsb"] == etd.identifier.first }

        pq_name = etd.file_sets.first.original_file.file_name.first
        if pq_name.blank?
          missing_files << etd.id
        else
          pq_id = "ProQuestID:" + pq_name.split("_").last.split(".").first
          match = csv.find { |r| r["proquest"].strip == pq_id }
          if match.present?
            row << [match["proquest"].strip, match["merritt"].strip, etd.identifier.first]
            count += 1
          else
            non_adrl << match["merritt"]
          end
        end
      end
    end
    puts "Merritt ETDs not found in ADRL #{non_adrl}"
    puts "No files found for ETDs: #{missing_files}"
    puts "Imported #{count} ETD Arks"
    puts "Import Complete #{Time.zone.now}"
  end
end
