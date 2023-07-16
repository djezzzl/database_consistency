# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process validators
    class ValidatorsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::MissingUniqueIndexChecker,
        Checkers::CaseSensitiveUniqueValidationChecker
      ].freeze

      private

      # @return [Array<Hash>]
      def check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
        Helper.parent_models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless configuration.enabled?('DatabaseConsistencyDatabases', Helper.database_name(model)) &&
                        configuration.enabled?(model.name.to_s)

            model.validators.flat_map do |validator|
              next unless validator.respond_to?(:attributes)

              validator.attributes.flat_map do |attribute|
                DebugContext.with(attribute: attribute) do
                  enabled_checkers.flat_map do |checker_class|
                    DebugContext.with(checker: checker_class) do
                      checker = checker_class.new(model, attribute, validator)
                      checker.report_if_enabled?(configuration)
                    end
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
