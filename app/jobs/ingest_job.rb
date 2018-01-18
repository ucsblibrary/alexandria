# frozen_string_literal: true

class IngestJob < ApplicationJob
  queue_as :ingest

  def perform(args)
    raise "No model specified in #{args.inspect}" if args[:model].blank?

    ::Importer::Factory.for(args[:model]).new(
      args[:attrs],
      args[:files]
    ).run
  end
end
