# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing uniqueness validator
    class UniqueIndexChecker < IndexChecker
      # Message templates
      VALIDATOR_MISSING = 'index is unique in the database but do not have uniqueness validator'

      private

      # We skip check when:
      #  - index is not unique
      def preconditions
        index.unique
      end

      # Table of possible statuses
      # | validation | status |
      # | ---------- | ------ |
      # | provided   | ok     |
      # | missing    | fail   |
      #
      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, VALIDATOR_MISSING)
        end
      end

      def valid?
        uniqueness_validators = model.validators.select {|validator| validator.kind == :uniqueness }

        uniqueness_validators.any? do |validator|
          validator.attributes.any? do |attribute|
            extract_index_columns(index.columns).sort == sorted_index_columns(attribute, validator)
          end
        end
      end

      # @return [Array<String>]
      def extract_index_columns(index_columns)
        return index_columns unless index_columns.is_a?(String)

        index_columns.split(',')
                     .map(&:strip)
                     .map { |str| str.gsub(/lower\(/i, 'lower(') }
                     .map { |str| str.gsub(/\(([^)]+)\)::\w+/, '\1') }
                     .map { |str| str.gsub(/'([^)]+)'::\w+/, '\1') }
      end

      def index_columns(attribute, validator)
        @index_columns ||= ([wrapped_attribute_name(attribute, validator)] + scope_columns(validator)).map(&:to_s)
      end

      def scope_columns(validator)
        @scope_columns ||= Array.wrap(validator.options[:scope]).map do |scope_item|
          model._reflect_on_association(scope_item)&.foreign_key || scope_item
        end
      end

      def sorted_index_columns(attribute, validator)
        @sorted_index_columns ||= index_columns(attribute, validator).sort
      end

      # @return [String]
      def wrapped_attribute_name(attribute, validator)
        if validator.options[:case_sensitive].nil? || validator.options[:case_sensitive]
          attribute
        else
          "lower(#{attribute})"
        end
      end
    end
  end
end
