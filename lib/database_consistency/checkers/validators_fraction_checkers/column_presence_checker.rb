# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if presence validator has non-null constraint in the database
    class ColumnPresenceChecker < ValidatorsFractionChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless on].freeze

      class Report < DatabaseConsistency::Report # :nodoc:
        attr_reader :table_name, :column_name

        def initialize(table_name:, column_name:, **args)
          super(**args)
          @table_name = table_name
          @column_name = column_name
        end

        def attributes
          super.merge(table_name: table_name, column_name: column_name)
        end
      end

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
        report_template(:fail, error_message: e.message)
      end

      def weak_option?
        validators.all? { |validator| validator.options.slice(*WEAK_OPTIONS).any? }
      end

      def report_message # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        can_be_null = column.null
        has_weak_option = weak_option?

        return report_template(:ok) if can_be_null == has_weak_option
        return report_template(:fail, error_slug: :possible_null) unless can_be_null

        if regular_column
          Report.new(
            status: :fail,
            error_slug: :null_constraint_missing,
            error_message: nil,
            table_name: model.table_name.to_s,
            column_name: attribute.to_s,
            **report_attributes
          )
        else
          Report.new(
            status: :fail,
            error_slug: :association_missing_null_constraint,
            error_message: nil,
            table_name: model.table_name.to_s,
            column_name: association_reflection.foreign_key.to_s,
            **report_attributes
          )
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
