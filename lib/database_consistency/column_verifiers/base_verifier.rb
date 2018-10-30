module DatabaseConsistency
  module ColumnVerifiers
    # The base class for column verifiers
    class BaseVerifier
      attr_reader :model, :column

      delegate :result, to: :report

      def initialize(model, column)
        @model = model
        @column = column
      end

      def report
        Report.new(column: column)
      end

      def self.verify(model, column)
        new(model, column).verify
      end
    end
  end
end
