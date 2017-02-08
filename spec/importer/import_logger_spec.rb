require 'rails_helper'
require 'importer'

describe Importer::ImportLogger do
  let(:dummy_class) { Class.new { include Importer::ImportLogger } }
  let(:fixture_path) { File.join(File.dirname(__FILE__), '..', 'fixtures') }
  let(:logfile) { "#{fixture_path}/logs/import_logger_spec.log" }
  let(:logfile2) { "#{fixture_path}/logs/import_logger_spec2.log" }
  let(:options) { { data: ['../data/objects-mcpeak/'], format: 'csv', metadata: ['../data/mss292(McPeak)-objects-URIed.csv'], number: nil, skip: 0, verbose: false, logfile: logfile2, loglevel: 'WARN', help: false, format_given: true, metadata_given: true, data_given: true, logfile_given: true, loglevel_given: true } }

  it 'has a logger' do
    expect(dummy_class.logger).to be_instance_of(Logger)
  end

  it 'can redirect to a log file' do
    expect(dummy_class.log_location(logfile)).to be(true)
  end

  it 'can write to its new location' do
    File.delete(logfile) if File.exist?(logfile)
    dummy_class.log_location(logfile)
    dummy_class.logger.debug('woof')
    expect(File.read(logfile)).to match(/woof/)
    File.delete(logfile) if File.exist?(logfile)
  end

  context 'command line logging options' do
    it 'sets logfile via an options array' do
      File.delete(logfile2) if File.exist?(logfile2)
      dummy_class.parse_log_options(options)
      dummy_class.logger.warn('meyow')
      expect(File.read(logfile2)).to match(/meyow/)
      File.delete(logfile2) if File.exist?(logfile2)
    end

    it 'sets log level via an options array' do
      File.delete(logfile2) if File.exist?(logfile2)
      dummy_class.parse_log_options(options)
      dummy_class.logger.warn('yellow submarine')
      expect(File.read(logfile2)).to match(/yellow submarine/)
      dummy_class.logger.debug('blue horse')
      expect(File.read(logfile2)).not_to match(/blue horse/)
      File.delete(logfile2) if File.exist?(logfile2)
    end
  end
end
