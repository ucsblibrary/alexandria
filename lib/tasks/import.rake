
# frozen_string_literal: true

require "csv"

namespace :import do
  desc "Import merritt arks from csv for UCSB ETDs"
  task :merr_arks, [:file_path] => :environment do |_t, args|
    puts "Beginning Import #{Time.zone.now}"
    missing_etds = []
    # CSV file contents would be
    # proquest,merritt,ucsb
    # ProQuestID:0035D,ark:/13030/m00999g9,ark:/48907/f30865g5
    CSV.foreach(args[:file_path], headers: true) do |row|
      ucsb_ark = row["ucsb"].split("/").last
      merr_ark = row["merritt"]
      begin
        etd = ETD.find ucsb_ark
        next if etd.merritt_id.present?
        etd.merritt_id = [merr_ark]
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
    puts "Beginning Import #{Time.zone.now}"

    unless Merritt::IngestEtd.collection_exists?
      puts "Aborting Import: Before you can import ETD records, "\
           "the ETD collection must exist."
      puts "Please import the ETD collection record first, "\
           "then re-try this import."
      return
    end

    first = args[:first]  || Merritt::Feed.first_page
    last  = args[:last]   || Merritt::Feed.last_page

    # Each page in merrit's
    # atom feed has 10 ETD entries
    first.upto(last).each do |page|
      begin
        feed = Merritt::Feed.parse(page)
        err = []
        feed.entries.each do |etd|
          merr_id = Merritt::Etd.merritt_id(etd)
          imported_etd = Merritt::Etd.where(merritt_id: merr_id)
            .order(last_modified: "DESC").first

          # Skip existing ETDs with Merritt arks
          # that have not been modified
          next if imported_etd.present? &&
                  imported_etd.last_modified == etd.last_modified
          # && ETD.where(id: Merritt::Etd.ark(etd)).present?
          # Skip existing ETDs with UCSB arks
          next if ETD.where(merritt_id: merr_id).present?

          begin
            file_path = Merritt::ImportEtd.import(etd)
            Merritt::Etd.find_or_create_by!(merritt_id: merr_id,
                                            last_modified: etd.last_modified)
            Merritt::IngestEtd.ingest(merr_id, file_path)
            # Ingest the imported ETD
            ## create XML mappings
            ## create Fedora Obj
            ## create solr index
          rescue StandardError => e
            err << "Page:#{page} Entry:#{etd.entry_id} raised error: #{e.inspect}"
          end
        end
        # TODO: How can we handle errors better?
        err.each { |e| puts e.inspect } if err.present?
      rescue StandardError => e
        puts "Page: #{page} could not be parsed"
        puts e.inspect
      end
    end
    puts "Ending Import #{Time.zone.now}"
  end
end
