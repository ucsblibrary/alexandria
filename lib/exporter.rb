# frozen_string_literal: true

module Exporter
  extend ActiveSupport::Autoload

  autoload :BaseExporter
  autoload :IdExporter
  autoload :LocalAuthorityExporter
end
