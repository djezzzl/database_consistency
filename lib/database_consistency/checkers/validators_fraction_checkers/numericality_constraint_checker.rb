# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if numericality validator has check constraint in the database
    class NumericalityConstraintChecker < ValidatorsFractionChecker
      private

      def filter(validator)
        validator.kind == :numericality
      end

      def preconditions
        model.connection.respond_to?(:check_constraints) &&
          model.connection.table_exists?(model.table_name) &&
          column &&
          validators.any?
      end

      def check
        if check_constraint_for_column?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :numericality_check_constraint_missing)
        end
      end

      def check_constraint_for_column?
        check_constraints.any? do |constraint|
          /\b#{Regexp.escape(column.name)}\b/i.match?(constraint.expression.to_s)
        end
      end

      def check_constraints
        @check_constraints ||= model.connection.check_constraints(model.table_name)
      rescue StandardError
        []
      end

      def column
        @column ||= model.columns.find { |field| field.name == attribute.to_s }
      end
    end
  end
end
