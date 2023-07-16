# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process validators
    class ValidatorsFractionsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::ColumnPresenceChecker
      ].freeze

      private

      # @return [Array<Hash>]
      def check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Helper.parent_models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless configuration.enabled?('DatabaseConsistencyDatabases', Helper.database_name(model)) &&
                        configuration.enabled?(model.name.to_s)

            model._validators.flat_map do |attribute, validators|
              DebugContext.with(attribute: attribute) do
                next unless attribute

                enabled_checkers.flat_map do |checker_class|
                  DebugContext.with(checker: checker_class) do
                    checker = checker_class.new(model, attribute, validators)
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
