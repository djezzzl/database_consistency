# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for checkers
    class BaseChecker
      # @param [DatabaseConsistency::Configuration]
      #
      # @return [Boolean]
      def self.enabled?(configuration)
        configuration.enabled?('DatabaseConsistencyCheckers', checker_name)
      end

      # @return [String]
      def self.checker_name
        @checker_name ||= name.split('::').last
      end

      # @param [Boolean] catch_errors
      #
      # @return [Hash, File, nil]
      def report(catch_errors: true)
        return unless preconditions

        @report ||= check
      rescue StandardError => e
        raise e unless catch_errors

        RescueError.call(e)
      end

      # @return [Hash, File, nil]
      def report_if_enabled?(configuration)
        report if enabled?(configuration)
      end

      # @param [DatabaseConsistency::Configuration] configuration
      #
      # @return [Boolean]
      def enabled?(configuration)
        configuration.enabled?(table_or_model_name, column_or_attribute_name, checker_name)
      end

      private

      def check
        raise NotImplementedError
      end

      def preconditions
        raise NotImplementedError
      end

      attr_reader :table_or_model, :column_or_attribute, :opts

      # @return [String]
      def checker_name
        @checker_name ||= self.class.checker_name
      end

      def table_or_model_name
        raise NotImplementedError
      end

      def column_or_attribute_name
        raise NotImplementedError
      end

      # @return [OpenStruct]
      def report_template(status, message = nil)
        OpenStruct.new(
          checker_name: checker_name,
          table_or_model_name: table_or_model_name,
          column_or_attribute_name: column_or_attribute_name,
          status: status,
          message: message
        )
      end
    end
  end
end
