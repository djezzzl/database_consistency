module DatabaseConsistency
  module ColumnVerifiers
    # This class verifies that column needs a presence validator
    class PresenceMissingVerifier < BaseVerifier
      VALIDATOR_MISSING = 'is required but do not have presence validator'.freeze

      def verify
        return if skip? || presence_validator? || inclusion_validator? || belongs_to_reflection?

        result(:fail, Helper.message(model, column, VALIDATOR_MISSING))
      end

      private

      def skip?
        column.null ||
          column.name == model.primary_key ||
          (model.record_timestamps? && %w[created_at updated_at].include?(column.name))
      end

      def presence_validator?
        model.validators.grep(ActiveModel::Validations::PresenceValidator).any? do |validator|
          Helper.check_inclusion?(validator.attributes, column.name)
        end
      end

      def inclusion_validator?
        model.validators.grep(ActiveModel::Validations::InclusionValidator).any? do |validator|
          Helper.check_inclusion?(validator.attributes, column.name)
        end
      end

      def belongs_to_reflection?
        model.reflect_on_all_associations.grep(ActiveRecord::Reflection::BelongsToReflection).any? do |reflection|
          Helper.check_inclusion?([reflection.foreign_key, reflection.foreign_type], column.name)
        end
      end
    end
  end
end
