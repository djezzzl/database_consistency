# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    # The base class for writers
    class BaseWriter
      attr_reader :results, :log_level, :config

      def initialize(results, log_level, config: Configuration.new)
        @results = results
        @log_level = log_level
        @config = config
      end

      def write?(status)
        status == :fail || debug?
      end

      def debug?
        log_level == 'DEBUG'
      end

      def self.write(results, log_level, config: Configuration.new)
        new(results, log_level, config: config).write
      end
    end
  end
end
