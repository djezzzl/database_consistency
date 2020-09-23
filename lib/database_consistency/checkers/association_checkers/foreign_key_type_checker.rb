# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key type is the same as associated model's primary key
    class ForeignKeyTypeChecker < AssociationChecker
      INCONSISTENT_TYPE = 'associated model key (%a_f) with type (%a_t) mismatches key (%b_f) with type (%b_t)'

      TYPES = {
        'serial' => 'integer',
        'integer' => 'integer',
        'int' => 'integer',
        'bigserial' => 'bigint',
        'bigint' => 'bigint',
        'bigint unsigned' => 'bigint unsigned'
      }.freeze

      private

      # We skip check when:
      #  - association is polymorphic association
      #  - association has `through` option
      #  - associated class doesn't exist
      def preconditions
        !association.polymorphic? && association.through_reflection.nil? && association.klass.present?
      rescue NameError
        false
      end

      # Table of possible statuses
      # | type         | status |
      # | ------------ | ------ |
      # | consistent   | ok     |
      # | inconsistent | fail   |
      def check
        if converted_type(base_column) == converted_type(associated_column)
          report_template(:ok)
        else
          report_template(:fail, render_text)
        end
      end

      # @return [String]
      def render_text
        INCONSISTENT_TYPE
          .gsub('%a_t', type(associated_column))
          .gsub('%a_f', associated_key)
          .gsub('%b_t', type(base_column))
          .gsub('%b_f', base_key)
      end

      # @return [String]
      def base_key
        @base_key ||= (
          if belongs_to_association?
            association.foreign_key
          else
            association.active_record_primary_key
          end
        ).to_s
      end

      # @return [String]
      def associated_key
        @associated_key ||= (
          if belongs_to_association?
            association.active_record_primary_key
          else
            association.foreign_key
          end
        ).to_s
      end

      # @return [ActiveRecord::ConnectionAdapters::Column]
      def base_column
        @base_column ||= column(association.active_record, base_key)
      end

      # @return [ActiveRecord::ConnectionAdapters::Column]
      def associated_column
        @associated_column ||= column(association.klass, associated_key)
      end

      # @return [DatabaseConsistency::Databases::Factory]
      def database_factory
        @database_factory ||= Databases::Factory.new(association.active_record.connection.adapter_name)
      end

      # @param [ActiveRecord::Base] model
      # @param [String] column_name
      #
      # @return [ActiveRecord::ConnectionAdapters::Column]
      def column(model, column_name)
        model.connection.columns(model.table_name).find { |column| column.name == column_name }
      end

      # @param [ActiveRecord::ConnectionAdapters::Column] column
      #
      # @return [String]
      def type(column)
        column.sql_type
      end

      # @param [ActiveRecord::ConnectionAdapters::Column]
      #
      # @return [String]
      def converted_type(column)
        database_factory.type(type(column)).convert
      end

      # @return [Boolean]
      def belongs_to_association?
        association.macro == :belongs_to
      end
    end
  end
end
