module DatabaseConsistency
  module Comparators
    # The comparator class for {{ActiveModel::Validations::PresenceValidator}}
    class PresenceComparator < BaseComparator
      WEAK_OPTIONS = %i[allow_nil allow_blank if unless].freeze
      # Message templates
      CONSTRAINT_MISSING = 'should be required in the database'.freeze
      POSSIBLE_NULL = 'is required but possible null value insert'.freeze

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missed                      | required | ok     |
      # | all missed                      | optional | fail   |
      def compare
        can_be_null = column.null
        has_weak_option = validator.options.slice(*WEAK_OPTIONS).any?

        if can_be_null == has_weak_option
          result(:ok, message)
        elsif can_be_null
          result(:fail, message(CONSTRAINT_MISSING))
        else
          result(:fail, message(POSSIBLE_NULL))
        end
      end

      private

      def message(template = nil)
        Helper.message(column, template)
      end
    end
  end
end
