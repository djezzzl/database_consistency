module DatabaseConsistency
  module Comparators
    # The base class for comparators
    class BaseComparator
      attr_reader :validator, :model, :column

      delegate :result, to: :report

      def initialize(validator, model, column)
        @validator = validator
        @model = model
        @column = column
      end

      def report
        Report.new(validator: validator, column: column)
      end

      def self.compare(validator, model, column)
        new(validator, model, column).compare
      end
    end
  end
end
