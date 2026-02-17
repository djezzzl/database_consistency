# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks if association's foreign key type covers associated model's primary key (same or bigger)
    class ForeignKeyTypeChecker < AssociationChecker # rubocop:disable Metrics/ClassLength
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :pk_name,
        :pk_type,
        :fk_name,
        :fk_type,
        :table_to_change,
        :type_to_set
      )

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
          association.macro != :has_and_belongs_to_many &&
          association.klass.table_exists?
      rescue NameError
        false
      end

      # Table of possible statuses
      # | type          | status |
      # | ------------- | ------ |
      # | covers        | ok     |
      # | doesn't cover | fail   |
      def check # rubocop:disable Metrics/MethodLength
        associated_columns_converted_types = associated_columns.map { |column| converted_type(column) }
        primary_columns_converted_types = primary_columns.map { |primary_column| converted_type(primary_column) }

        if covers?(associated_columns_converted_types, primary_columns_converted_types)
          report_template(:ok)
        else
          report_template(:fail, error_slug: :inconsistent_types)
        end
      rescue Errors::MissingField => e
        DatabaseConsistency::Report.new(
          status: :fail,
          error_slug: nil,
          error_message: e.message,
          **report_attributes
        )
      end

      def report_template(status, error_slug: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          table_to_change: table_to_change,
          type_to_set: primary_columns.map { |primary_column| converted_type(primary_column).convert },
          fk_type: associated_columns.map { |column| converted_type(column).type }.join('+'),
          fk_name: associated_keys.join('+'),
          pk_type: primary_columns.map { |primary_column| converted_type(primary_column).type }.join('+'),
          pk_name: primary_keys.join('+'),
          **report_attributes
        )
      end

      def table_to_change
        @table_to_change ||= if belongs_to_association?
                               association.active_record.table_name
                             else
                               association.klass.table_name
                             end
      end

      # @return [Array<String>]
      def primary_keys
        @primary_keys ||= if belongs_to_association?
                            Helper.extract_columns(association.association_primary_key)
                          else
                            Helper.extract_columns(association.active_record_primary_key)
                          end
      end

      # @return [Array<String>]
      def associated_keys
        @associated_keys ||= Helper.extract_columns(association.foreign_key)
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
      def primary_columns
        @primary_columns ||= primary_keys.map do |primary_key|
          if belongs_to_association?
            column(association.klass, primary_key)
          else
            column(association.active_record, primary_key)
          end
        end
      end

      # @return [Array<ActiveRecord::ConnectionAdapters::Column>]
      def associated_columns
        @associated_columns ||= associated_keys.map do |associated_key|
          if belongs_to_association?
            column(association.active_record, associated_key)
          else
            column(association.klass, associated_key)
          end
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

      def covers?(associated_types, primary_types)
        associated_types.zip(primary_types).all? do |associated_type, primary_type|
          associated_type.cover?(primary_type)
        end
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
