# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process all comparators
    class ModelsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::ColumnPresenceChecker,
        Checkers::BelongsToPresenceChecker,
        Checkers::MissingUniqueIndexChecker
      ].freeze

      private

      # @return [Array<Hash>]
      def check
        Helper.parent_models.flat_map do |model|
          model.validators.flat_map do |validator|
            validator.attributes.flat_map do |attribute|
              CHECKERS.map do |checker_class|
                checker = checker_class.new(model, attribute, validator)
                checker.report if checker.enabled?(configuration)
              end
            end
          end
        end.compact
      end
    end
  end
end
