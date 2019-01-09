# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for table checkers
    class TableChecker < BaseChecker
      attr_reader :table, :column

      def initialize(table, column)
        @table = table
        @column = column
      end

      def column_or_attribute_name
        @column_or_attribute_name ||= column.name.to_s
      end

      def table_or_model_name
        @table_or_model_name ||= table.name.to_s
      end
    end
  end
end
