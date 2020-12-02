# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for table checkers
    class IndexChecker < BaseChecker
      attr_reader :model, :index

      def initialize(model, index)
        @model = model
        @index = index
      end

      def column_or_attribute_name
        @column_or_attribute_name ||= index.name.to_s
      end

      def table_or_model_name
        @table_or_model_name ||= model.name.to_s
      end

      private

      def index_columns
        index.columns.map(&:to_s)
      end
    end
  end
end
