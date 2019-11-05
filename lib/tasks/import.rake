
# frozen_string_literal: true

require "csv"
require "merritt/ingest_etd"
require "merritt/import_etd"

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

  desc "Update solr index for all ETDs"
  task update_solr_index: :environment do
    puts "Beginning index #{Time.zone.now}"
    ETD.find_each(&:update_index)
    puts "Indexing Complete #{Time.zone.now}"
  end

  desc "Import merritt etds from atom feed"
  task :merritt_etds, [:first, :last] => :environment do |_t, args|
    puts "Beginning Import #{Time.zone.now}"

    collection = Merritt::IngestEtd.collection
    if collection.blank?
      puts "Before you can import ETD records, "\
           "the ETD collection must exist."
      abort "Aborting Rake Task: Please import the ETD collection first, "\
            "then re-try this task."
    end

    first = Merritt::Feed.first_page.to_i
    last  = Merritt::Feed.last_page.to_i

    first = args[:first].to_i if args[:first].present? && args[:first].to_i >= first
    last = args[:last].to_i if args[:last].present? && args[:last].to_i <= last

    last_parsed_feed = Merritt::Feed.order(last_modified: "DESC").first
    last_parsed_page = last_parsed_feed.blank? ? 0 : last_parsed_feed.last_parsed_page
    last_modified    = last_parsed_feed.blank? ? nil : last_parsed_feed.last_modified

    # Each page in merritt's
    # atom feed has 10 ETD entries
    last.downto(first).each do |page|
      next if last_parsed_page.positive? && last_parsed_page < page
      retries ||= 0
      puts "Retry:#{retries}" unless retries.zero?
      puts "Parsing Page:#{page}"
      begin
        feed    = Merritt::Feed.parse(page)
        entries = feed.entries.sort_by(&:updated)
        # last_parsed_page = page
        # last_modified    = entries.first.updated
        skipped = []
        ezids   = []

        entries.each_with_index do |etd, i|
          merritt_id = "ark" + etd.entry_id.split("ark").last
          # Existing ETDs with Merritt arks
          results = ETD.where(merritt_id: merritt_id)
          if results.any?
            existing_etd = results.first
            # Skip ADRL ETDs with EZID arks for now
            id = existing_etd.identifier.first
            if id != merritt_id && id.match("48907")
              ezids << id
              next
            end
          end

          # Do not import/ingest existing Merritt ETDs with no updates
          if last_parsed_feed.present? && etd.updated < last_parsed_feed.last_modified
            skipped << merritt_id
            next
          end

          begin
            pid = fork do
              file_path = Merritt::ImportEtd.import(etd)
              Merritt::IngestEtd.ingest(merritt_id, file_path)
            end
            last_parsed_page = page
            last_modified = etd.updated
            puts "Ingesting ETD:#{merritt_id} in the background with PID #{pid}"
            Process.detach pid

            # TODO: Once resque workers are finished importing
            # Remove folders for each ETD imported
          rescue StandardError => e
            puts "Page:#{page} Entry:#{etd.entry_id} raised error: #{e.inspect}"
            Merritt::Feed.create_or_update(page, entries[i - 1].updated)
            abort "Aborting Task: Please fix the error first, "\
                  "then re-try this task."
          end
        end
      rescue Net::HTTPError => nhe
        puts "Page:#{page} responded with Net::HTTPError:"
        puts nhe.inspect
        sleep(3)
        retry if (retries += 1) < 3
        Merritt::Feed.create_or_update(page - 1, last_modified) if
          (page - 1).positive? && last_modified.present?
        abort "Aborting Task: 3 failed retries to parse page #{page}"
      rescue StandardError => e
        puts "Page:#{page} could not be parsed"
        puts e.inspect
        Merritt::Feed.create_or_update(page - 1, last_modified) if
          (page - 1).positive? && last_modified.present?
        abort "Aborting Rake Task: Please fix feed parse error first, "\
              "then re-try this task."
      end
      puts "No feed updates for ETDs #{skipped.inspect}" if skipped.present?
      puts "Skipped ETDs with EZIDs #{ezids}" if ezids.present?
      puts "Page:#{page} parsed OK"
    end
    Merritt::Feed.create_or_update(last_parsed_page, last_modified) if
      last_parsed_page.positive? && last_modified.present?
    puts "Updating ETD Collection index #{Time.zone.now}"
    collection = Merritt::IngestEtd.collection
    collection.update_index
    puts "Ending Import #{Time.zone.now}"
  end
end
