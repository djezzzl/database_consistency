module DatabaseConsistency
  module Comparators
    # The base class for comparators
    class BaseComparator
      attr_reader :validator, :column

      delegate :result, to: :report

      def initialize(validator, column)
        @validator = validator
        @column = column
      end

      def report
        Report.new(validator: validator, column: column)
      end

      def self.compare(validator, column)
        new(validator, column).compare
      end
    end
  end
end
