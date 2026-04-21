# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class AutofixWriter < BaseWriter
      UnknownCheckerError = Class.new(StandardError)

      SLUG_TO_GENERATOR = {
        association_missing_index: Autofix::AssociationMissingIndex,
        association_missing_null_constraint: Autofix::NullConstraintMissing,
        association_foreign_type_missing_null_constraint: Autofix::NullConstraintMissing,
        has_one_missing_unique_index: Autofix::HasOneMissingUniqueIndex,
        inconsistent_types: Autofix::InconsistentTypes,
        missing_foreign_key: Autofix::MissingForeignKey,
        missing_unique_index: Autofix::HasOneMissingUniqueIndex,
        null_constraint_missing: Autofix::NullConstraintMissing,
        redundant_index: Autofix::RedundantIndex,
        redundant_unique_index: Autofix::RedundantIndex,
        small_primary_key: Autofix::InconsistentTypes,
        three_state_boolean: Autofix::NullConstraintMissing
      }.freeze

      def write
        validate_scope!
        unique_generators.each(&:fix!)
      end

      private

      def validate_scope!
        return unless opts.is_a?(Array)

        known = Checkers::BaseChecker.descendants.map(&:checker_name)
        unknown = opts - known
        return if unknown.empty?

        raise UnknownCheckerError,
              "unknown checker(s): #{unknown.join(', ')}. Known: #{known.sort.uniq.join(', ')}"
      end

      def unique_generators
        results
          .select(&method(:fix?))
          .map(&method(:generator))
          .compact
          .uniq(&method(:unique_key))
      end

      def fix?(report)
        report.status == :fail && scoped?(report)
      end

      def scoped?(report)
        return true unless opts.is_a?(Array)

        opts.include?(report.checker_name)
      end

      def generator(report)
        klass = SLUG_TO_GENERATOR[report.error_slug]
        klass&.new(report)
      end

      def unique_key(generator)
        [generator.class, generator.attributes]
      end
    end
  end
end
