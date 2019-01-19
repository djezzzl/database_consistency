# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for table checkers
    class ColumnChecker < BaseChecker
      attr_reader :model, :column

      def initialize(model, column)
        @model = model
        @column = column
      end

      def column_or_attribute_name
        @column_or_attribute_name ||= column.name.to_s
      end

      def table_or_model_name
        @table_or_model_name ||= model.name.to_s
      end
    end
  end
end
