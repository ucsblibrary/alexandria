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
#      logger.set_log_location("/somewhere/out/there.log")
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
      def self.set_log_location(logfile)
        pathname = Pathname.new(logfile)
        FileUtils.touch logfile
        # outfile = File.new(logfile, "a") # Ensure it exists, but don't zero it out
        # outfile.close
        raise ArgumentError.new("Can't write to logfile #{logfile}") unless pathname.writable?
        @logger = Logger.new(logfile)
        true # return true if everything worked out okay
      end

    # Addition
    def self.included(base)
      class << base
        def logger
          ImportLogger.logger
        end
        def set_log_location(logfile)
          ImportLogger.set_log_location(logfile)
        end
      end
    end

    def logger
      ImportLogger.logger
    end
  end

end
