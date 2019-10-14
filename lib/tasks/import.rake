
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

    collection = Merritt::IngestEtd.collection
    if collection.blank?
      puts "Before you can import ETD records, "\
           "the ETD collection must exist."
      abort "Aborting Rake Task: Please import the ETD collection first, "\
            "then re-try this task."
    end

    first = args[:first].to_i || Merritt::Feed.first_page
    last  = args[:last].to_i  || Merritt::Feed.last_page
    parsed = true

    home_feed = Merritt::Feed.parse
    last_parse = Merritt::Feed.order(last_modified: "DESC").first

    # Do not parse feed when there are no new/updated
    # Merritt ETDs to import/ingest
    abort "Aborting Task: No new updates from feed" if last_parse.present? &&
                                                       (home_feed.last_modified <=
                                                       last_parse.last_modified)

    # Each page in merritt's
    # atom feed has 10 ETD entries
    last.downto(first).each do |page|
      begin
        feed = Merritt::Feed.parse(page)
        feed.entries.reverse.each_with_index do |etd, i|
          merritt_id = "ark" + etd.entry_id.split("ark").last
          # Existing ETDs with Merritt arks
          # query = { "has_model_ssim": "ETD", "merritt_id_ssm": merritt_id}
          # solr_query = ActiveFedora::SolrQueryBuilder.construct_query(query)
          # results = ActiveFedora::SolrService.query(solr_query, rows: 1)
          results = ETD.where(merritt_id: merritt_id)
          if results.any?
            existing_etd = results.first
            # Skip ADRL ETDs with EZID arks for now
            break if existing_etd.identifier.first != merritt_id
          end

          # Do not import/ingest existing Merritt ETDs with no updates
          if last_parse.present? && etd.last_modified <= last_parse.last_modified
            puts "Skipping ETD #{merritt_id}: No new updates from feed"
            break
          end

          begin
            pid = fork do
              file_path = Merritt::ImportEtd.import(etd)
              Merritt::IngestEtd.ingest(merritt_id, file_path)
            end
            puts "Ingesting ETD:#{merritt_id} in the background with PID #{pid}"
            Process.detach pid

            # TODO: Once resque workers are finished importing
            # Update collection index
            # Remove folders for each ETd imported
          rescue StandardError => e
            prev_etd = feed.entries[i - 1]
            Merritt::Feed.find_or_create_by!(last_parsed_page: page,
                                             last_modified: prev_etd.last_modified)
            parsed = false
            puts "Page:#{page} Entry:#{etd.entry_id} raised error: #{e.inspect}"
            abort "Aborting Task: Please fix the error first, "\
                  "then re-try this task."
          end
        end
        if parsed
          merritt_feed = Merritt::Feed.find_or_create_by!(last_parsed_page: first)
          merritt_feed.last_modified = feed.last_modified
          merritt_feed.save!
        end
      rescue StandardError => e
        puts "Page:#{page} could not be parsed"
        puts e.inspect
        abort "Aborting Rake Task: Please fix feed parse error first, "\
              "then re-try this task."
      end
    end
    puts "Ending Import #{Time.zone.now}"
  end
end
