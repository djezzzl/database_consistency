module DatabaseConsistency
  module Writers
    # The base class for writers
    class BaseWriter
      attr_reader :results, :log_level

      def initialize(results, log_level)
        @results = results
        @log_level = log_level
      end

      def write?(status)
        status == :fail
      end

      def debug?
        log_level == 'DEBUG'
      end

      def self.write(results, log_level)
        new(results, log_level).write
      end
    end
  end
end
