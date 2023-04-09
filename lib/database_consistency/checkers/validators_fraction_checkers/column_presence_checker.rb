# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if presence validator has non-null constraint in the database
    class ColumnPresenceChecker < ValidatorsFractionChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless on].freeze

      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :table_name,
        :column_name
      )

      private

      def filter(validator)
        validator.kind == :presence
      end

      def preconditions
        (regular_column || association) && validators.any?
      end

      def report_template(status, column_name:, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          table_name: model.table_name.to_s,
          column_name: column_name,
          **report_attributes
        )
      end

      def weak_option?
        validators.all? { |validator| validator.options.slice(*WEAK_OPTIONS).any? }
      end

      def check
        return analyse(attribute.to_s, type: :null_constraint_missing) if regular_column

        reports = [analyse(association.foreign_key.to_s, type: :association_missing_null_constraint)]
        if association.polymorphic?
          reports << analyse(association.foreign_type.to_s, type: :association_foreign_type_missing_null_constraint)
        end

        reports.compact!
        reports.any? ? reports : nil
      end

      def analyse(column_name, type:)
        field = column(column_name)
        return if field.nil?

        can_be_null = field.null
        has_weak_option = weak_option?

        return report_template(:ok, column_name: column_name) if can_be_null == has_weak_option
        return report_template(:fail, error_slug: :possible_null, column_name: column_name) unless can_be_null

        report_template(:fail, error_slug: type, column_name: column_name)
      end

      def regular_column
        @regular_column ||= column(attribute.to_s)
      end

      def association
        @association ||=
          model
          .reflect_on_all_associations
          .find { |reflection| reflection.belongs_to? && reflection.name.to_s == attribute.to_s }
      end

      def column(name)
        model.columns.find { |field| field.name == name.to_s }
      end
    end
  end
end
