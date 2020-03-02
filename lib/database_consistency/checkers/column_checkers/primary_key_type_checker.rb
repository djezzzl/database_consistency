# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class PrimaryKeyTypeChecker < ColumnChecker
      # Message templates
      VALIDATOR_MISSING = 'column has int/serial type but recommended to have bigint/bigserial/uuid'

      private

      VALID_TYPES = %w[bigserial bigint uuid].freeze
      SQLITE_ADAPTER_NAME = 'SQLite'

      # We skip check when:
      #  - column is not a primary key
      #  - database is SQLite3
      def preconditions
        primary_field? && !sqlite?
      end

      # Table of possible statuses
      # | bigint/bigserial/uuid | status |
      # | --------------------- | ------ |
      # | yes                   | ok     |
      # | no                    | fail   |
      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, VALIDATOR_MISSING)
        end
      end

      # @return [Boolean]
      def valid?
        VALID_TYPES.any? do |type|
          column.sql_type.to_s.match?(type)
        end
      end

      # @return [Boolean]
      def primary_field?
        column.name.to_s == model.primary_key.to_s
      end

      # @return [Boolean]
      def sqlite?
        model.connection.adapter_name == SQLITE_ADAPTER_NAME
      end
    end
  end
end
