# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if non polymorphic +belongs_to+ association has foreign key constraint
    class ForeignKeyChecker < AssociationChecker
      MISSING_FOREIGN_KEY = 'should have foreign key in the database'

      private

      # We skip check when:
      #  - association isn't belongs_to association
      #  - association is polymorphic
      def preconditions
        supported? && association.belongs_to? && !association.polymorphic?
      end

      def supported?
        return false if ActiveRecord::VERSION::MAJOR < 5 && ActiveRecord::Base.connection_config[:adapter] == 'sqlite3'

        true
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
    end
  end
end
