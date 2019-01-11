# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if uniqueness validator has unique index in the database
    class MissingUniqueIndexChecker < ValidatorChecker
      MISSING_INDEX = 'should have unique index in the database'

      def column_or_attribute_name
        @column_or_attribute_name ||= index_columns.join('+')
      end

      private

      # We skip check when:
      #  - validator is not a uniqueness validator
      def preconditions
        validator.kind == :uniqueness
      end

      # Table of possible statuses
      # | unique index | status |
      # | ------------ | ------ |
      # | persisted    | ok     |
      # | missing      | fail   |
      def check
        if unique_index
          report_template(:ok)
        else
          report_template(:fail, MISSING_INDEX)
        end
      end

      def unique_index
        @unique_index ||= model.connection.indexes(model.table_name).find do |index|
          index.unique && index.columns.sort == sorted_index_columns
        end
      end

      def index_columns
        @index_columns ||= ([attribute] + Array.wrap(validator.options[:scope])).map(&:to_s)
      end

      def sorted_index_columns
        @sorted_index_columns ||= index_columns.sort
      end
    end
  end
end
