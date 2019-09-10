# frozen_string_literal: true

require "csv"

namespace :import do
  desc "Import merritt arks from csv for UCSB ETDs"
  task :merritt_arks, [:file_path] => :environment do |_t, args|
    puts "Beginning Import #{Time.zone.now}"
    missing_etds = []
    # CSV file contents would be
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

  desc "Import UCSB ETD arks into CSV for merritt ark mappings"
  task :adrl_arks, [:input_file, :output_file] => :environment do |_t, args|
    puts "Beginning import #{Time.zone.now}"
    # CSV file contents would be
    # merritt,proquest
    # ark:/13030/m00999g9,ProQuestID:0035D
    csv = CSV.read(args[:input_file], headers: true)
    count = 0

    # rewrite CSV with each run
    # using 'w' mode
    CSV.open(args[:output_file],
             "w",
             write_headers: true,
             headers: %w[proquest merritt ucsb]) do |row|
      ETD.find_each do |etd|
        next if etd.merritt_id.present?
        begin
          pq_name = etd.file_sets.first.original_file.file_name.first
          pq_id = "ProQuestID:" + pq_name.split("_").last.split(".").first
          match = csv.find { |r| r["proquest"].strip == pq_id }
          if match.present?
            row << [
              match["proquest"].strip,
              match["merritt"].strip,
              etd.identifier.first,
            ]
            count += 1
          end
        rescue NoMethodError => e
          puts "Error occured with #{etd.id} => #{e.inspect}"
        end
      end
    end
    puts "Imported #{count} ETD Arks"
    puts "Import Complete #{Time.zone.now}"
  end

  desc "Import merritt etds from atom feed"
  task :merritt_etds, [:first, :last] => :environment do |_t, args|
    puts "Beginning import #{Time.zone.now}"

    first = args[:first] || Merritt::Feed.first_page
    last  = args[:last] || Merritt::Feed.last_page

    # Each page in merrit's
    # atom feed has 10 ETD entries
    first.upto(last).each do |page|
      parsed_feed = Merritt::Feed.parse(page)
      parsed_feed.entries.each do |etd_entry|
        # Ingest the ETD entry
          # download xml
          # download pdf & suppl files
          # create XML mappings
          # ingest into Fedora
          # create solr index
        # Create Merritt::Etd entry in db
      end
      # Create Merritt::Feed entry in db
      page += 1
    end
  end
end
