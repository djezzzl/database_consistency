# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key has index in the database
    class MissingIndexChecker < AssociationChecker
      # Message templates
      MISSING_INDEX = 'associated model should have proper index in the database'
      MISSING_UNIQUE_INDEX = 'associated model should have proper unique index in the database'

      private

      # We skip check when:
      #  - association isn't a `HasOne` or `HasMany`
      #  - association has `through` option
      #  - associated class doesn't exist
      def preconditions
        %i[
          has_one
          has_many
        ].include?(association.macro) && association.through_reflection.nil? && association.klass
      rescue NameError
        false
      end

      # Table of possible statuses
      # | index        | status |
      # | ------------ | ------ |
      # | persisted    | ok     |
      # | missing      | fail   |
      def check
        if unique_has_one_association?
          check_unique_has_one
        else
          check_remaining
        end
      end

      def check_unique_has_one
        if unique_index
          report_template(:ok)
        else
          report_template(:fail, MISSING_UNIQUE_INDEX)
        end
      end

      def check_remaining
        if index
          report_template(:ok)
        else
          report_template(:fail, MISSING_INDEX)
        end
      end

      def unique_has_one_association?
        association.scope.nil? && association.macro == :has_one && !association.options[:as].present?
      end

      def unique_index
        @unique_index ||= association.klass.connection.indexes(association.klass.table_name).find do |index|
          index_keys(index) == association_keys && index.unique
        end
      end

      def index
        @index ||= association.klass.connection.indexes(association.klass.table_name).find do |index|
          index_keys(index, limit: association_keys.size) == association_keys
        end
      end

      def association_keys
        @association_keys ||= [association.foreign_key, association.type].compact.map(&:to_s).sort
      end

      def index_keys(index, limit: nil)
        return unless index.columns.is_a?(Array)

        columns = index.columns

        if limit
          columns.first(limit).sort
        else
          columns
        end
      end
    end
  end
end
