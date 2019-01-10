# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks PresenceValidator
    class ColumnPresenceChecker < ValidatorChecker
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless].freeze
      # Message templates
      CONSTRAINT_MISSING = 'should be required in the database'
      POSSIBLE_NULL = 'is required but possible null value insert'

      private

      # We skip check when:
      #  - validator is not a presence validator
      #  - there is no column in the database with given name
      def preconditions
        validator.kind == :presence && column
      end

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missed                      | required | ok     |
      # | all missed                      | optional | fail   |
      def check
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
        @column ||= model.columns.select.find { |field| field.name == attribute.to_s }
      end
    end
  end
end
