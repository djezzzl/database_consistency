# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class NullConstraintChecker < TableChecker
      # Message templates
      VALIDATOR_MISSING = 'is required but do not have presence validator'

      private

      # Table of possible statuses
      # | validation | database | status |
      # | ---------- | -------- | ------ |
      # | missed     | required | fail   |
      #
      # We skip check when:
      #  - column hasn't null constraint
      #  - column has default value
      #  - column is a primary key
      #  - column is a timestamp
      #  - presence validation exists
      #  - inclusion validation exists
      #  - belongs_to reflection exists with given column as foreign key or foreign type
      def check
        return if skip? ||
                  validator?(ActiveModel::Validations::PresenceValidator) ||
                  validator?(ActiveModel::Validations::InclusionValidator) ||
                  belongs_to_reflection?

        report_template(:fail, VALIDATOR_MISSING)
      end

      def skip?
        column.null ||
          !column.default.nil? ||
          column.name == model.primary_key ||
          timestamp_field?
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
