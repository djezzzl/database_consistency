# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if non polymorphic +belongs_to+ association has foreign key constraint
    class ForeignKeyChecker < AssociationChecker
      private

      # We skip check when:
      #  - underlying models belong to different databases
      #  - association isn't belongs_to association
      #  - association is polymorphic
      def preconditions
        supported? &&
          association.belongs_to? && !association.polymorphic? &&
          same_database?
      end

      def same_database?
        Helper.connection_config(model) == Helper.connection_config(association.klass)
      end

      def supported?
        return false if ActiveRecord::VERSION::MAJOR < 5 && Helper.adapter == 'sqlite3'

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
          report_template(:fail, nil, :missing_foreign_key)
        end
      end
    end
  end
end
