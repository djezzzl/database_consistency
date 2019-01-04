module DatabaseConsistency
  module Processors
    # The class to process all comparators
    class ModelsProcessor < BaseProcessor
      CHECKERS = {
        presence: Checkers::PresenceValidationChecker
      }.freeze

      private

      # @return [Array<Hash>]
      def check
        Helper.parent_models.flat_map do |model|
          model.validators.flat_map do |validator|
            next unless (checker_class = CHECKERS[validator.kind])

            validator.attributes.map do |attribute|
              checker = checker_class.new(model, attribute, validator: validator)
              checker.report if checker.enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
