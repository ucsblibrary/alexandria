# frozen_string_literal: true

require "rails_helper"
require "importer"

describe Importer::ImportLogger do
  let(:dummy_class) { Class.new { include Importer::ImportLogger } }
  let(:logfile) { "#{fixture_path}/logs/import_logger_spec.log" }
  let(:logfile2) { "#{fixture_path}/logs/import_logger_spec2.log" }

  let(:options) do
    {
      data: ["../data/objects-mcpeak/"],
      data_given: true,
      format: "csv",
      format_given: true,
      help: false,
      logfile: logfile2,
      logfile_given: true,
      loglevel: "WARN",
      loglevel_given: true,
      metadata: ["../data/mss292(McPeak)-objects-URIed.csv"],
      metadata_given: true,
      number: nil,
      skip: 0,
      verbose: false,
    }
  end

  it "has a logger" do
    expect(dummy_class.logger).to be_instance_of(Logger)
  end

  it "can redirect to a log file" do
    expect(dummy_class.log_location(logfile)).to be(true)
  end

  it "can write to its new location" do
    File.delete(logfile) if File.exist?(logfile)
    dummy_class.log_location(logfile)
    dummy_class.logger.debug("woof")
    expect(File.read(logfile)).to match(/woof/)
    File.delete(logfile) if File.exist?(logfile)
  end

  context "command line logging options" do
    it "sets logfile via an options array" do
      File.delete(logfile2) if File.exist?(logfile2)
      dummy_class.parse_log_options(options)
      dummy_class.logger.warn("meyow")
      expect(File.read(logfile2)).to match(/meyow/)
      File.delete(logfile2) if File.exist?(logfile2)
    end

    it "sets log level via an options array" do
      File.delete(logfile2) if File.exist?(logfile2)
      dummy_class.parse_log_options(options)
      dummy_class.logger.warn("yellow submarine")
      expect(File.read(logfile2)).to match(/yellow submarine/)
      dummy_class.logger.debug("blue horse")
      expect(File.read(logfile2)).not_to match(/blue horse/)
      File.delete(logfile2) if File.exist?(logfile2)
    end
  end
end
