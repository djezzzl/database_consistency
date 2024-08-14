# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process enums
    class EnumsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::EnumTypeChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/MethodLength
        Helper.models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless model_enabled?(model)

            model.defined_enums.keys.flat_map do |enum|
              DebugContext.with(enum: enum) do
                enabled_checkers.flat_map do |checker_class|
                  DebugContext.with(checker: checker_class) do
                    checker = checker_class.new(model, enum)
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
