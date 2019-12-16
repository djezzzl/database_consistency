# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process validators
    class ValidatorsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::BelongsToPresenceChecker,
        Checkers::MissingUniqueIndexChecker
      ].freeze

      private

      # @return [Array<Hash>]
      def check # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Helper.parent_models.flat_map do |model|
          next unless configuration.enabled?(model)

          model.validators.flat_map do |validator|
            next unless validator.respond_to?(:attributes)

            validator.attributes.flat_map do |attribute|
              enabled_checkers.map do |checker_class|
                checker = checker_class.new(model, attribute, validator)
                checker.report_if_enabled?(configuration)
              end
            end
          end
        end.compact
      end
    end
  end
end
