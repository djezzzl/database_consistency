# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process columns
    class ColumnsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::NullConstraintChecker,
        Checkers::LengthConstraintChecker,
        Checkers::PrimaryKeyTypeChecker,
        Checkers::EnumValueChecker,
        Checkers::ThreeStateBooleanChecker,
        Checkers::ImplicitOrderingChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/MethodLength
        Helper.parent_models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless model_enabled?(model)

            model.columns.flat_map do |column|
              DebugContext.with(column: column.name) do
                enabled_checkers.flat_map do |checker_class|
                  DebugContext.with(checker: checker_class) do
                    checker = checker_class.new(model, column)
                    checker.report_if_enabled?(configuration)
                  end
                end
              end
            end
          end
        end.compact
      end
    end
  end
end
