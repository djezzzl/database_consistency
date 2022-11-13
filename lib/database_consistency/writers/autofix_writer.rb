# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class AutofixWriter < BaseWriter
      SLUG_TO_GENERATOR = {
        missing_foreign_key: Autofix::MissingForeignKey,
        null_constraint_missing: Autofix::NullConstraintMissing,
        association_missing_null_constraint: Autofix::NullConstraintMissing,
        redundant_index: Autofix::RedundantIndex,
        redundant_unique_index: Autofix::RedundantIndex,
        inconsistent_types: Autofix::InconsistentTypes,
        association_missing_index: Autofix::AssociationMissingIndex,
        has_one_missing_unique_index: Autofix::HasOneMissingUniqueIndex
      }.freeze

      def write
        unique_generators.each(&:fix!)
      end

      private

      def unique_generators
        results
          .select(&method(:fix?))
          .map(&method(:generator))
          .compact
          .uniq(&method(:unique_key))
      end

      def fix?(report)
        report.status == :fail
      end

      def generator(report)
        klass = SLUG_TO_GENERATOR[report.error_slug]
        klass&.new(report)
      end

      def unique_key(report)
        [report.class, report.attributes]
      end
    end
  end
end
