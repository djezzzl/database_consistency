module DatabaseConsistency
  module ColumnVerifiers
    # This class verifies that column needs a presence validator
    class PresenceMissingVerifier < BaseVerifier
      VALIDATOR_MISSING = 'is required but do not have presence validator'.freeze

      def verify
        result(:fail, Helper.message(column, VALIDATOR_MISSING)) unless skip? || validator?
      end

      private

      def skip?
        column.null ||
          column.name == model.primary_key ||
          (model.record_timestamps? && %w[created_at updated_at].include?(column.name))
      end

      def validator?
        model.validators.grep(ActiveModel::Validations::PresenceValidator).any? do |validator|
          validator.attributes.include?(column.name) || validator.attributes.include?(column.name.to_sym)
        end
      end
    end
  end
end
