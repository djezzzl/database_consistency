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
        Checkers::ThreeStateBooleanChecker
      ].freeze

      private

      def check
        Helper.parent_models.flat_map do |model|
          next unless configuration.enabled?(model.name.to_s)

          model.columns.flat_map do |column|
            enabled_checkers.flat_map do |checker_class|
              checker = checker_class.new(model, column)
              checker.report_if_enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
