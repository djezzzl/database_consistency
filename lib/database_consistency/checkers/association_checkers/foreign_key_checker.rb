# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if non polymorphic +belongs_to+ association has foreign key constraint
    class ForeignKeyChecker < AssociationChecker
      class Report < DatabaseConsistency::Report
        attr_reader :primary_table, :primary_key, :foreign_table, :foreign_key

        def initialize(primary_table:, foreign_table:, primary_key:, foreign_key:, **args)
          super(**args)
          @primary_table = primary_table
          @primary_key = primary_key
          @foreign_table = foreign_table
          @foreign_key = foreign_key
        end

        def attributes
          super.merge(
            primary_table: primary_table,
            primary_key: primary_key,
            foreign_table: foreign_table,
            foreign_key: foreign_key
          )
        end
      end

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
          Report.new(
            status: :fail,
            error_message: nil,
            error_slug: :missing_foreign_key,
            primary_table: model.table_name.to_s,
            primary_key: model.primary_key.to_s,
            foreign_table: association.table_name.to_s,
            foreign_key: association.foreign_key.to_s,
            **report_attributes
          )
        end
      end
    end
  end
end
