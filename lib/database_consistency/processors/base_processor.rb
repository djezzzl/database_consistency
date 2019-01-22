# frozen_string_literal: true

module DatabaseConsistency
  # The module for processors
  module Processors
    def self.reports(configuration)
      [
        ColumnsProcessor,
        ValidatorsProcessor,
        AssociationsProcessor
      ].flat_map do |processor|
        processor.new(configuration).reports
      end
    end

    # The base class for processors
    class BaseProcessor
      attr_reader :configuration

      # @param [DatabaseConsistency::Configuration] configuration
      def initialize(configuration = nil)
        @configuration = configuration || Configuration.new
      end

      # @return [Array<Hash>]
      def reports
        @reports ||= check
      end

      # @return [Array<Class>]
      def enabled_checkers
        self.class::CHECKERS.select { |checker| checker.enabled?(configuration) }
      end

      private

      def check
        raise NotImplementedError
      end
    end
  end
end
