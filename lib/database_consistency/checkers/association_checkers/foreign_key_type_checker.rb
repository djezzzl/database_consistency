# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key type covers associated model's primary key (same or bigger)
    class ForeignKeyTypeChecker < AssociationChecker
      class Report < DatabaseConsistency::Report # :nodoc:
        attr_reader :pk_name, :pk_type, :fk_name, :fk_type

        def initialize(fk_name: nil, fk_type: nil, pk_name: nil, pk_type: nil, **args)
          super(**args)
          @fk_name = fk_name
          @fk_type = fk_type
          @pk_name = pk_name
          @pk_type = pk_type
        end

        def attributes
          super.merge(
            fk_name: fk_name,
            fk_type: fk_type,
            pk_name: pk_name,
            pk_type: pk_type
          )
        end
      end

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
      def check # rubocop:disable Metrics/MethodLength
        if converted_type(associated_column).cover?(converted_type(primary_column))
          report_template(:ok)
        else
          report_template(:fail, error_slug: :inconsistent_types)
        end
      rescue Errors::MissingField => e
        Report.new(
          status: :fail,
          error_slug: nil,
          error_message: e.message,
          **report_attributes
        )
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          fk_type: converted_type(associated_column).type,
          fk_name: associated_key,
          pk_type: converted_type(primary_column).type,
          pk_name: primary_key,
          **report_attributes
        )
      end

      # @return [String]
      def primary_key
        @primary_key ||= if belongs_to_association?
                           association.association_primary_key
                         else
                           association.active_record_primary_key
                         end.to_s
      end

      # @return [String]
      def associated_key
        @associated_key ||= association.foreign_key.to_s
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
