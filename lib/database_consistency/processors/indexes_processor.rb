# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process indexes
    class IndexesProcessor < BaseProcessor
      CHECKERS = [
        Checkers::UniqueIndexChecker,
        Checkers::RedundantIndexChecker,
        Checkers::RedundantUniqueIndexChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Helper.parent_models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless model_enabled?(model)

            indexes = model.connection.indexes(model.table_name)

            indexes.flat_map do |index|
              DebugContext.with(index: index.name) do
                enabled_checkers.flat_map do |checker_class|
                  DebugContext.with(checker: checker_class) do
                    checker = checker_class.new(model, index)
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
