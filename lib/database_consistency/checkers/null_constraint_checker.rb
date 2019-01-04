# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class NullConstraintChecker < BaseChecker
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

      def column_or_attribute_name
        column_or_attribute.name.to_s
      end

      def table_or_model_name
        table_or_model.name.to_s
      end

      def skip?
        column_or_attribute.null ||
          !column_or_attribute.default.nil? ||
          column_or_attribute.name == table_or_model.primary_key ||
          timestamp_field?
      end

      def timestamp_field?
        table_or_model.record_timestamps? && %w[created_at updated_at].include?(column_or_attribute.name)
      end

      def validator?(validator_class)
        table_or_model.validators.grep(validator_class).any? do |validator|
          Helper.check_inclusion?(validator.attributes, column_or_attribute.name)
        end
      end

      def belongs_to_reflection?
        table_or_model.reflect_on_all_associations.grep(ActiveRecord::Reflection::BelongsToReflection).any? do |r|
          Helper.check_inclusion?([r.foreign_key, r.foreign_type], column_or_attribute.name)
        end
      end
    end
  end
end
