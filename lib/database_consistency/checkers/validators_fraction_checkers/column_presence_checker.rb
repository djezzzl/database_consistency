# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if presence validator has non-null constraint in the database
    class ColumnPresenceChecker < ValidatorsFractionChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless on].freeze
      # Message templates
      CONSTRAINT_MISSING = 'column should be required in the database'
      ASSOCIATION_FOREIGN_KEY_CONSTRAINT_MISSING = 'association foreign key column should be required in the database'
      POSSIBLE_NULL = 'column is required but there is possible null value insert'

      private

      def filter(validator)
        validator.kind == :presence
      end

      # We skip the check when there are no presence validators
      def preconditions
        validators.any? && !association?
      end

      def association?
        model._reflect_on_association(attribute)&.macro == :has_one
      end

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missing                     | required | ok     |
      # | all missing                     | optional | fail   |
      def check
        report_message
      rescue Errors::MissingField => e
        report_template(:fail, e.message)
      end

      def weak_option?
        validators.all? { |validator| validator.options.slice(*WEAK_OPTIONS).any? }
      end

      def report_message
        can_be_null = column.null
        has_weak_option = weak_option?

        return report_template(:ok) if can_be_null == has_weak_option
        return report_template(:fail, POSSIBLE_NULL) unless can_be_null

        if regular_column
          report_template(:fail, CONSTRAINT_MISSING)
        else
          report_template(:fail, ASSOCIATION_FOREIGN_KEY_CONSTRAINT_MISSING)
        end
      end

      def column
        @column ||= regular_column ||
                    association_reference_column ||
                    (raise Errors::MissingField, "column (#{attribute}) is missing in table (#{model.table_name}) but used for presence validation") # rubocop:disable Layout/LineLength
      end

      def regular_column
        @regular_column ||= column_for_name(attribute.to_s)
      end

      def column_for_name(name)
        model.columns.find { |field| field.name == name.to_s }
      end

      def association_reference_column
        return unless association_reflection

        column_for_name(association_reflection.foreign_key)
      end

      def association_reflection
        model
          .reflect_on_all_associations
          .find { |reflection| reflection.belongs_to? && reflection.name == attribute }
      end
    end
  end
end
