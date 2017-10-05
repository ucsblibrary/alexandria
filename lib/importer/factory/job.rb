# frozen_string_literal: true

require "resque"

module Importer::Factory::Job
  @queue = :ingest

  def self.perform(args)
    ::Importer::Factory.for(args["model"]).new(
      args["attrs"],
      args["files"]
    ).run
  end
end
