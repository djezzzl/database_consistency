# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if uniqueness validator has unique index in the database
    class MissingUniqueIndexChecker < ValidatorChecker
      MISSING_INDEX = 'model should have proper unique index in the database'

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
          index.unique && extract_index_columns(index.columns).sort == sorted_index_columns
        end
      end

      # @return [Array<String>]
      def extract_index_columns(index_columns)
        return index_columns unless index_columns.is_a?(String)

        index_columns.split(',')
                     .map(&:strip)
                     .map { |str| str.gsub(/lower\(/i, 'lower(') }
                     .map { |str| str.gsub(/\(([^)]+)\)::\w+/, '\1') }
      end

      def index_columns
        @index_columns ||= ([wrapped_attribute_name] + scope_columns).map(&:to_s)
      end

      def scope_columns
        @scope_columns ||= Array.wrap(validator.options[:scope]).map do |scope_item|
          model._reflect_on_association(scope_item)&.foreign_key || scope_item
        end
      end

      def sorted_index_columns
        @sorted_index_columns ||= index_columns.sort
      end

      # @return [String]
      def wrapped_attribute_name
        if validator.options[:case_sensitive].nil? || validator.options[:case_sensitive]
          attribute
        else
          "lower(#{attribute})"
        end
      end
    end
  end
end
