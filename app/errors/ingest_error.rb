# frozen_string_literal: true

class IngestError < RuntimeError
  attr_reader :data, :metadata, :model, :reached

  def initialize(options = {})
    @data = options.fetch(:data, nil)
    @metadata = options.fetch(:metadata, nil)
    @model = options.fetch(:model, nil)
    @reached = options.fetch(:reached, 0)
  end
end
