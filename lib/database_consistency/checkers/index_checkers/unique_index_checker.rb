# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class UniqueIndexChecker < IndexChecker
      # Message templates
      VALIDATOR_MISSING = 'index is unique in the database but do not have uniqueness validator'

      private

      # We skip check when:
      #  - index is not unique
      def preconditions
        index.unique
      end

      # Table of possible statuses
      # | validation | status |
      # | ---------- | ------ |
      # | provided   | ok     |
      # | missing    | fail   |
      #
      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, VALIDATOR_MISSING)
        end
      end

      def valid?
        model.validators.grep(ActiveRecord::Validations::UniquenessValidator).any? do |validator|
          # scope can be either nil, a symbol/string or an array of symbols/strings
          scope = [validator.options&.dig(:scope)].flatten.compact

          validator.attributes.any? do |attribute|
            validator_attributes = ([attribute] + scope).compact.map(&:to_s)

            (index_columns - validator_attributes).blank? && (validator_attributes - index_columns).blank?
          end
        end
      end
    end
  end
end
