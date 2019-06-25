# frozen_string_literal: true
require 'csv'

namespace :import do
  desc "Import merritt arks from csv for UCSB ETDs"

  task merritt_arks: :environment do
    # To run the task on the ETD fixture at
    # spec/fixtures/proquest/zipped/ETD_ucsb_0035D_13132.zip
    # CSV file contents would be as below
    # Proquest ID,Meritt Ark,UCSB Ark
    # ProQuestID:0035D,ark:/13030/m00999g9,ark:/48907/f30865g5

    puts "Beginning Import"
    csv_text = File.read('tmp/ucsb_merritt_etds.csv')
    csv = CSV.parse(csv_text, :headers => true)
    missing_etds = []

    csv.each do |row|
      ucsb_ark = row[2].split('/').last
      merritt_ark = row[1]

      begin
        etd = ETD.find ucsb_ark
        next if etd.merritt_id.present?
        etd.merritt_id = Array[merritt_ark]
        etd.save
        puts "Updated UCSB ETD: #{ucsb_ark}"
      rescue ActiveFedora::ObjectNotFoundError
        missing_etds << ucsb_ark
      end
    end
    puts "Missing ETDs: #{missing_etds.inspect}" unless missing_etds.blank?
    puts "Import Complete"
  end
end