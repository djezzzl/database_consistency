# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      SLUG_TO_WRITER = {
        missing_foreign_key: Simple::Base.with('should have foreign key in the database'),
        inconsistent_types: Simple::InconsistentTypes,
        has_one_missing_unique_index: Simple::Base.with('associated model should have proper unique index in the database'), # rubocop:disable Layout/LineLength
        association_missing_index: Simple::Base.with('associated model should have proper index in the database'),
        length_validator_missing: Simple::Base.with('column has limit in the database but do not have length validator'), # rubocop:disable Layout/LineLength
        length_validator_greater_limit: Simple::Base.with('column has greater limit in the database than in length validator'), # rubocop:disable Layout/LineLength
        length_validator_lower_limit: Simple::Base.with('column has lower limit in the database than in length validator'), # rubocop:disable Layout/LineLength
        null_constraint_misses_validator: Simple::Base.with('column is required in the database but do not have presence validator'), # rubocop:disable Layout/LineLength
        small_primary_key: Simple::Base.with('column has int/serial type but recommended to have bigint/bigserial/uuid'), # rubocop:disable Layout/LineLength
        missing_uniqueness_validation: Simple::Base.with('index is unique in the database but do not have uniqueness validator'), # rubocop:disable Layout/LineLength
        missing_unique_index: Simple::Base.with('model should have proper unique index in the database'),
        possible_null: Simple::Base.with('column is required but there is possible null value insert'),
        null_constraint_missing: Simple::Base.with('column should be required in the database'),
        association_missing_null_constraint: Simple::Base.with('association foreign key column should be required in the database'), # rubocop:disable Layout/LineLength
        null_constraint_association_misses_validator: Simple::NullConstraintAssociationMissesValidator,
        redundant_index: Simple::RedundantIndex,
        redundant_unique_index: Simple::RedundantUniqueIndex
      }.freeze

      def write
        results.each do |result|
          next unless write?(result.status)

          writer = writer(result)

          puts writer.msg
        end
      end

      private

      def write?(status)
        status == :fail || config.debug?
      end

      def writer(report)
        klass = SLUG_TO_WRITER[report.error_slug] || Simple::ErrorMessage
        klass.new(report, config: config)
      end
    end
  end
end
