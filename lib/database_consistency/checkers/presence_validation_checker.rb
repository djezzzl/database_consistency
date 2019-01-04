module DatabaseConsistency
  module Checkers
    # This class checks PresenceValidator
    class PresenceValidationChecker < BaseChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless].freeze
      # Message templates
      CONSTRAINT_MISSING = 'should be required in the database'.freeze
      POSSIBLE_NULL = 'is required but possible null value insert'.freeze

      private

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missed                      | required | ok     |
      # | all missed                      | optional | fail   |
      #
      # We skip check when:
      #  - there is no column in the database with given name
      def check
        return unless column

        can_be_null = column.null
        has_weak_option = validator.options.slice(*WEAK_OPTIONS).any?

        if can_be_null == has_weak_option
          report_template(:ok)
        elsif can_be_null
          report_template(:fail, CONSTRAINT_MISSING)
        else
          report_template(:fail, POSSIBLE_NULL)
        end
      end

      def column
        @column ||= Helper.find_field(table_or_model, column_or_attribute.to_s)
      end

      def column_or_attribute_name
        column_or_attribute.to_s
      end

      def table_or_model_name
        table_or_model.name.to_s
      end

      def validator
        opts[:validator]
      end
    end
  end
end
