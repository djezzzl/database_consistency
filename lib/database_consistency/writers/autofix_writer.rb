# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class AutofixWriter < BaseWriter
      SLUG_TO_GENERATOR = {
        missing_foreign_key: Autofix::MissingForeignKey
      }.freeze

      def write
        reports.each do |report|
          next unless fix?(report)

          fix(report)
        end
      end

      private

      def reports
        results.then(&Helpers::Pipes.method(:unique))
      end

      def fix?(report)
        report.status == :fail
      end

      def fix(report)
        klass = SLUG_TO_GENERATOR[report.error_slug]
        return unless klass

        klass.new(report).fix!
      end
    end
  end
end
