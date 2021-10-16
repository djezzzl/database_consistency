# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if a foreign key column for a required +belongs_to+ has no not null constraint
    class MissingNotNullConstraintChecker < ColumnChecker
      MISSING_NOT_NULL_CONSTRAINT = 'FK allows for null in the database, but is required in the model'

      private

      def preconditions
        recent_rails? &&
          column.null &&
          foreign_key &&
          presence_validation_present?
      end

      def check
        report_template(:fail, MISSING_NOT_NULL_CONSTRAINT)
      end

      def foreign_key
        model.connection
             .foreign_keys(model.table_name)
             .find { |fk| fk.options[:column] == column.name }
      end

      def reflection
        model
          .reflections
          .values
          .find { |r| r.join_foreign_key == column.name }
      end

      def presence_validation_present?
        model
          .validators_on(reflection.name)
          .grep(ActiveRecord::Validations::PresenceValidator)
          .any?
      end

      def recent_rails?
        ActiveRecord::VERSION::MAJOR >= 5
      end
    end
  end
end
