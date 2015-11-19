# See https://github.com/ruby-rdf/rdf-n3/issues/16
#
require 'rdf'
require 'rdf/n3'
module RDF::N3
  module Parser
    def readline
      @line = @input.readline
      @lineno += 1
      @line.force_encoding(Encoding::UTF_8)
      # @line.encode!(Encoding::UTF_8) if @line.respond_to?(:encode!) # for Ruby 1.9+
      puts "readline[#{@lineno}]: #{@line.dump}" if $verbose
      @pos = 0
      @line
    rescue EOFError => e
      @line = nil
      @pos = 0
    end
  end
end
