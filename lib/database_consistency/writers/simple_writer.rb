# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      SLUG_TO_WRITER = {
        association_missing_index: Simple::AssociationMissingIndex,
        association_missing_null_constraint: Simple::AssociationMissingNullConstraint,
        has_one_missing_unique_index: Simple::HasOneMissingUniqueIndex,
        inconsistent_types: Simple::InconsistentTypes,
        length_validator_greater_limit: Simple::LengthValidatorGreaterLimit,
        length_validator_lower_limit: Simple::LengthValidatorLowerLimit,
        length_validator_missing: Simple::LengthValidatorMissing,
        missing_foreign_key: Simple::MissingForeignKey,
        missing_unique_index: Simple::MissingUniqueIndex,
        missing_uniqueness_validation: Simple::MissingUniquenessValidation,
        null_constraint_association_misses_validator: Simple::NullConstraintAssociationMissesValidator,
        null_constraint_misses_validator: Simple::NullConstraintMissesValidator,
        null_constraint_missing: Simple::NullConstraintMissing,
        possible_null: Simple::PossibleNull,
        redundant_index: Simple::RedundantIndex,
        redundant_unique_index: Simple::RedundantUniqueIndex,
        small_primary_key: Simple::SmallPrimaryKey,
        inconsistent_enum_type: Simple::InconsistentEnumType,
        missing_foreign_key_cascade: Simple::MissingForeignKeyCascade
      }.freeze

      def write
        results.select(&method(:write?))
               .map(&method(:writer))
               .group_by(&:unique_key)
               .each_value do |writers|
          puts message(writers)
        end
      end

      private

      def message(writers)
        msg = writers.first.msg
        return msg if writers.size == 1

        "#{msg}. Total grouped offenses: #{writers.size}"
      end

      def write?(report)
        report.status == :fail || config.debug?
      end

      def writer(report)
        klass = SLUG_TO_WRITER[report.error_slug] || Simple::DefaultMessage
        klass.new(report, config: config)
      end
    end
  end
end
