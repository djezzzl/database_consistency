# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key type covers associated model's primary key (same or bigger)
    class ForeignKeyTypeChecker < AssociationChecker
      INCONSISTENT_TYPE = "foreign key (%a_f) with type (%a_t) doesn't cover primary key (%b_f) with type (%b_t)"

      private

      # We skip check when:
      #  - association is polymorphic association
      #  - association is has_and_belongs_to_many
      #  - association has `through` option
      #  - associated class doesn't exist
      def preconditions
        !association.polymorphic? &&
          association.through_reflection.nil? &&
          association.klass.present? &&
          association.macro != :has_and_belongs_to_many
      rescue NameError
        false
      end

      # Table of possible statuses
      # | type          | status |
      # | ------------- | ------ |
      # | covers        | ok     |
      # | doesn't cover | fail   |
      def check
        if converted_type(associated_column).cover?(converted_type(primary_column))
          report_template(:ok)
        else
          report_template(:fail, render_text)
        end
      rescue Errors::MissingField => e
        report_template(:fail, e.message)
      end

      # @return [String]
      def render_text
        INCONSISTENT_TYPE
          .gsub('%a_t', type(associated_column))
          .gsub('%a_f', associated_key)
          .gsub('%b_t', type(primary_column))
          .gsub('%b_f', primary_key)
      end

      # @return [String]
      def primary_key
        @primary_key ||= (
          if belongs_to_association?
            association.association_primary_key
          else
            association.association_primary_key
          end
        ).to_s
      end

      # @return [String]
      def associated_key
        @associated_key ||= (
          if belongs_to_association?
            association.foreign_key
          else
            association.foreign_key
          end
        ).to_s
      end

      # @return [ActiveRecord::ConnectionAdapters::Column]
      def primary_column
        @primary_column ||= if belongs_to_association?
                           column(association.klass, primary_key)
                         else
                           column(association.active_record, primary_key)
                         end
      end

      # @return [ActiveRecord::ConnectionAdapters::Column]
      def associated_column
        @associated_column ||= if belongs_to_association?
                                 column(association.active_record, associated_key)
                               else
                                 column(association.klass, associated_key)
                               end
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
        model.connection.columns(model.table_name).find { |column| column.name == column_name } ||
          (raise Errors::MissingField, missing_field_error(model.table_name, column_name))
      end

      # @return [String]
      def missing_field_error(table_name, column_name)
        "association (#{association.name}) of class (#{association.active_record}) relies on "\
          "field (#{column_name}) of table (#{table_name}) but it is missing"
      end

      # @param [ActiveRecord::ConnectionAdapters::Column] column
      #
      # @return [String]
      def type(column)
        column.sql_type
      end

      # @param [ActiveRecord::ConnectionAdapters::Column]
      #
      # @return [DatabaseConsistency::Databases::Types::Base]
      def converted_type(column)
        database_factory.type(type(column))
      end

      # @return [Boolean]
      def belongs_to_association?
        association.macro == :belongs_to
      end
    end
  end
end
