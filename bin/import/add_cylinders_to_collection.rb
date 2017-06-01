#!/usr/bin/env ruby
# frozen_string_literal: true

# Add all cylinder records to the cylinder collection.

# CAUTION! This script assumes that all existing AudioRecording
# records are cylinders.  If you have existing non-cylinder
# audio records, don't use this script.

$stdout.sync = true # flush output immediately
puts "Loading environment"
require File.expand_path("../../config/environment", __FILE__)

# Find or create the right collection:
require "importer"
collection = Importer::Factory::CollectionFactory.new(Importer::Cylinder::COLLECTION_ATTRIBUTES).find_or_create

puts "Adding cylinder records to: #{collection.title}"
puts "Number of cylinder records: #{AudioRecording.count}"

start_time = Time.zone.now
puts "Start time: #{start_time.strftime("%Y-%m-%d %H:%M:%S")}"

puts "Adding records to collection"
i = 0
AudioRecording.find_each do |audio|
  i += 1
  (i % 100).zero? ? print(i) : print(".")
  next if audio.local_collection_id.include?(collection.id)
  audio.local_collection_id += [collection.id]
  audio.save!
end
print "\n"

# Update the solr index to add the new collection members
collection.update_index

end_time = Time.zone.now
puts "End time: #{end_time.strftime("%Y-%m-%d %H:%M:%S")}"

delta = (end_time - start_time) / 60.0
printf "Finished in %0.2f minutes.\n", delta
