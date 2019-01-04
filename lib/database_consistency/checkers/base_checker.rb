module DatabaseConsistency
  module Checkers
    # The base class for checkers
    class BaseChecker
      def initialize(table_or_model, column_or_attribute, opts = {})
        @table_or_model = table_or_model
        @column_or_attribute = column_or_attribute
        @opts = opts
      end

      # @return [Hash]
      def report
        @report ||= check
      end

      # @param [DatabaseConsistency::Configuration] configuration
      def enabled?(configuration)
        configuration.enabled?(checker_name, table_or_model_name, column_or_attribute_name)
      end

      private

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
