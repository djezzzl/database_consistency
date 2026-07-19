# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if numericality validator has check constraint in the database
    class NumericalityConstraintChecker < ValidatorsFractionChecker
      SQL_KEYWORDS = %w[
        and or not null is true false in like between case when then else end check
        exists select where having order group limit offset distinct all any some
        from join on using as by union into values set update delete insert with
      ].freeze
      PLAIN_IDENTIFIER_PATTERN =
        /\b([a-zA-Z_][a-zA-Z0-9_]*(?:\.[a-zA-Z_][a-zA-Z0-9_]*)?)\b(?!\s*\()/.freeze

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
          constraint_columns(constraint.expression).include?(column.name.downcase)
        end
      end

      def check_constraints
        @check_constraints ||= model.connection.check_constraints(model.table_name)
      rescue StandardError
        []
      end

      def constraint_columns(expression)
        expression_sql = expression.to_s
        # Captures identifiers in three forms:
        # 1) "double quoted", 2) `backtick quoted`, 3) plain SQL identifiers.
        # Plain identifiers followed by `(` are excluded to skip SQL function names.
        quoted_identifiers = expression_sql.scan(/"([^"]+)"|`([^`]+)`/).flatten.compact
        # Only the column part is needed for comparison, so `table.column` is
        # reduced to `column`.
        # `(?!\s*\()` excludes function names such as `ABS(`.
        plain_identifiers = expression_sql.scan(PLAIN_IDENTIFIER_PATTERN)
                                          .flatten
                                          .map { |identifier| identifier.split('.').last }

        (quoted_identifiers + plain_identifiers).map(&:downcase).reject { |identifier| SQL_KEYWORDS.include?(identifier) }
      end

      def column
        @column ||= model.columns.find { |field| field.name == attribute.to_s }
      end
    end
  end
end
