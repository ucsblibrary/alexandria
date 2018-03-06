# frozen_string_literal: true

class IngestJob < ApplicationJob
  queue_as :ingest

  def perform(args)
    ::Importer::Factory.for(args[:model]).new(
      args[:attrs],
      args[:files]
    ).run
  end
end
