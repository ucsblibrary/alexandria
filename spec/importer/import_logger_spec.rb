require 'rails_helper'
require 'importer'

describe Importer::ImportLogger do

  let(:dummy_class) { Class.new { include Importer::ImportLogger } }
  let(:fixture_path) { File.join(File.dirname(__FILE__), '..', 'fixtures')}
  let(:logfile) { "#{fixture_path}/logs/import_logger_spec.log" }

  it "has a logger" do
    expect(dummy_class.logger).to be_instance_of(Logger)

  end

  it "can redirect to a log file" do
    expect(dummy_class.set_log_location(logfile)).to be(true)
  end

  it "can write to its new location" do
    File.delete(logfile) if File.exist?(logfile)
    dummy_class.set_log_location(logfile)
    dummy_class.logger.debug("woof")
    expect(File.read(logfile)).to match(/woof/)
    File.delete(logfile) if File.exist?(logfile)
  end

end
