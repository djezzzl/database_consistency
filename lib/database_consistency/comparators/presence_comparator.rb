module DatabaseConsistency
  module Comparators
    # The comparator for {{ActiveModel::Validations::PresenceValidator}}
    module PresenceComparator
      module_function

      WEAK_OPTIONS = %i[allow_nil allow_blank if unless].freeze
      CONSTRAINT_MISSING = 'database field should have: "null: false"'.freeze
      POSSIBLE_NULL = 'possible null value insert'.freeze

      # Table of possible statuses
      # | allow_nil/allow_blank/if/unless | database | status |
      # | ------------------------------- | -------- | ------ |
      # | at least one provided           | required | fail   |
      # | at least one provided           | optional | ok     |
      # | all missed                      | required | ok     |
      # | all missed                      | optional | fail   |
      def compare(validator, column)
        can_be_null = column.null
        has_weak_option = validator.options.slice(*WEAK_OPTIONS).any?

        if can_be_null == has_weak_option
          ComparisonResult.format(:ok)
        elsif can_be_null
          ComparisonResult.format(:fail, CONSTRAINT_MISSING)
        else
          ComparisonResult.format(:fail, POSSIBLE_NULL)
        end
      end
    end
  end
end
