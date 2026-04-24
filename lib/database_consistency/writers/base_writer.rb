# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    # The base class for writers
    class BaseWriter
      attr_reader :results, :config, :opts

      def initialize(results, config: Configuration.new, opts: nil)
        @results = results
        @config = config
        @opts = opts
      end

      def self.write(results, config: Configuration.new, opts: nil)
        new(results, config: config, opts: opts).write
      end
    end
  end
end
