# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class NullConstraintChecker < TableChecker
      # Message templates
      VALIDATOR_MISSING = 'is required but do not have presence validator'

      private

      # We skip check when:
      #  - column hasn't null constraint
      #  - column has default value
      #  - column is a primary key
      #  - column is a timestamp
      def preconditions
        !column.null && column.default.nil? && !primary_field? && !timestamp_field?
      end

      # Table of possible statuses
      # | validation | status |
      # | ---------- | ------ |
      # | provided   | ok     |
      # | missing    | fail   |
      #
      # We consider PresenceValidation, InclusionValidation or BelongsTo reflection using this column
      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, VALIDATOR_MISSING)
        end
      end

      def valid?
        validator?(ActiveModel::Validations::PresenceValidator) ||
          validator?(ActiveModel::Validations::InclusionValidator) ||
          belongs_to_reflection?
      end

      def primary_field?
        column.name.to_s == model.primary_key.to_s
      end

      def timestamp_field?
        model.record_timestamps? && %w[created_at updated_at].include?(column.name)
      end

      def validator?(validator_class)
        model.validators.grep(validator_class).any? do |validator|
          Helper.check_inclusion?(validator.attributes, column.name)
        end
      end

      def belongs_to_reflection?
        model.reflect_on_all_associations.grep(ActiveRecord::Reflection::BelongsToReflection).any? do |r|
          Helper.check_inclusion?([r.foreign_key, r.foreign_type], column.name)
        end
      end
    end
  end
end
