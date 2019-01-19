# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if required +belongs_to+ has foreign key constraint
    class BelongsToPresenceChecker < ValidatorChecker
      MISSING_FOREIGN_KEY = 'model should have proper foreign key in the database'

      private

      # We skip check when:
      #  - validator is a not a presence validator
      #  - there is no belongs_to association with given name
      #  - belongs_to association is polymorphic
      def preconditions
        validator.kind == :presence && association && !association.polymorphic?
      end

      # Table of possible statuses
      # | foreign key | status |
      # | ----------- | ------ |
      # | persisted   | ok     |
      # | missing     | fail   |
      def check
        if model.connection.foreign_keys(model.table_name).find { |fk| fk.column == association.foreign_key.to_s }
          report_template(:ok)
        else
          report_template(:fail, MISSING_FOREIGN_KEY)
        end
      end

      def association
        @association ||= model.reflect_on_association(attribute)
      end
    end
  end
end
