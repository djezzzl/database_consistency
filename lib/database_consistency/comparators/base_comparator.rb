module DatabaseConsistency
  module Comparators
    # The base class for comparators
    class BaseComparator
      attr_reader :validator, :column

      delegate :result, to: :comparison

      private_class_method :new

      def initialize(validator, column)
        @validator = validator
        @column = column
      end

      def comparison
        Comparison.for(validator, column)
      end

      def self.compare(validator, column)
        new(validator, column).compare
      end
    end
  end
end
