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
    end
  end
end
