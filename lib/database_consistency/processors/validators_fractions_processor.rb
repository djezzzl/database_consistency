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
      def check
        Helper.parent_models.flat_map do |model|
          next unless configuration.enabled?(model.name.to_s)

          model._validators.flat_map do |attribute, validators|
            next unless attribute

            enabled_checkers.map do |checker_class|
              checker = checker_class.new(model, attribute, validators)
              checker.report_if_enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
