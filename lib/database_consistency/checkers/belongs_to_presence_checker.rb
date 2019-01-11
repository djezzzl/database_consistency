# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if required +belongs_to+ has foreign key constraint
    class BelongsToPresenceChecker < ValidatorChecker
      MISSING_FOREIGN_KEY = 'should have foreign key in the database'

      private

      # We skip check when:
      #  - validator is a not a presence validator
      #  - there is no belongs_to reflection with given name
      #  - belongs_to reflection is polymorphic
      def preconditions
        validator.kind == :presence && reflection && !reflection.polymorphic?
      end

      # Table of possible statuses
      # | foreign key | status |
      # | ----------- | ------ |
      # | persisted   | ok     |
      # | missing     | fail   |
      def check
        if model.connection.foreign_keys(model.table_name).find { |fk| fk.column == reflection.foreign_key.to_s }
          report_template(:ok)
        else
          report_template(:fail, MISSING_FOREIGN_KEY)
        end
      end

      def reflection
        @reflection ||= model.reflect_on_association(attribute)
      end
    end
  end
end
