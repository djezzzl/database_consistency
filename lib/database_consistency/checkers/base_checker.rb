# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for checkers
    class BaseChecker
      # @return [Hash, nil]
      def report
        return unless preconditions

        @report ||= check
      end

      # @param [DatabaseConsistency::Configuration] configuration
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
        @checker_name ||= self.class.name.split('::').last
      end

      def table_or_model_name
        raise NotImplementedError
      end

      def column_or_attribute_name
        raise NotImplementedError
      end

      # @return [Hash]
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
