# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if presence validator has non-null constraint in the database
    class ColumnPresenceChecker < ValidatorsFractionChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless].freeze
      # Message templates
      CONSTRAINT_MISSING = 'column should be required in the database'
      POSSIBLE_NULL = 'column is required but there is possible null value insert'

      private

      def filter(validator)
        validator.kind == :presence
      end

      # We skip check when:
      #  - there is no presence validators
      #  - there is no column in the database with given name
      def preconditions
        validators.any? && column
      end

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missing                     | required | ok     |
      # | all missing                     | optional | fail   |
      def check
        can_be_null = column.null
        has_weak_option = validators.all? { |validator| validator.options.slice(*WEAK_OPTIONS).any? }

        if can_be_null == has_weak_option
          report_template(:ok)
        elsif can_be_null
          report_template(:fail, CONSTRAINT_MISSING)
        else
          report_template(:fail, POSSIBLE_NULL)
        end
      end

      def column
        @column ||= model.columns.select.find { |field| field.name == attribute.to_s }
      end
    end
  end
end
