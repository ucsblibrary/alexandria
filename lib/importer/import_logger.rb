require 'logger'

module Importer
  # Add a common logging system to any part of the Importer module.
  # See http://ruby-doc.org/stdlib-2.2.3/libdoc/logger/rdoc/Logger.html for more documentation.
  # Logs should be compatible with splunk indexing. See also http://dev.splunk.com/view/logging-best-practices/SP-CAAADP6.
  # NOTE: If log location isn't set, it defaults to $stdout
  # @example
  #  module Importer::Whatever
  #    include Importer::ImportLogger
  #    def foo
  #      logger.log_location("/somewhere/out/there.log")
  #      logger.debug "tisk, tisk, it looks like rain"
  #    end
  #  end

  module ImportLogger
    def self.logger
      @logger ||= Logger.new($stdout)
    end

    def self.logger=(logger)
      @logger = logger
    end

    # Redirect where the logging goes.
    # Return true if successful. Raise an error if the logfile isn't writable.
    # @param [String] logfile The full path the logfile location
    # @return [Boolean] return true if successful
    def self.log_location(logfile)
      pathname = Pathname.new(logfile)
      FileUtils.touch logfile
      raise ArgumentError, "Can't write to logfile #{logfile}" unless pathname.writable?
      @logger = Logger.new(logfile)
      true # return true if everything worked out okay
    end

    # Process any logging options passed on comamnd line
    # @param [Hash] options As passed by trollop on the command line
    def self.parse_log_options(options)
      if options[:logfile]
        log_location(options[:logfile])
      else
        logger
      end
      # DEBUG,INFO,WARN or ERROR
      if options[:loglevel]
        case options[:loglevel].upcase
        when 'DEBUG'
          @logger.level = Logger::DEBUG
        when 'INFO'
          @logger.level = Logger::INFO
        when 'WARN'
          @logger.level = Logger::WARN
        when 'ERROR'
          @logger.level = Logger::ERROR
        else
          @logger.warn "#{options[:loglevel]} isn't a valid log level. Defaulting to DEBUG."
          @logger.level = Logger::DEBUG
        end
      end
    end

    # Addition
    def self.included(base)
      class << base
        def logger
          ImportLogger.logger
        end

        def log_location(logfile)
          ImportLogger.log_location(logfile)
        end

        def parse_log_options(options)
          ImportLogger.parse_log_options(options)
        end
      end
    end

    def logger
      ImportLogger.logger
    end
  end
end
