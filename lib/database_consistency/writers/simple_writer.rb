# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      COLORS = {
        blue: "\e[34m",
        yellow: "\e[33m",
        green: "\e[32m",
        red: "\e[31m"
      }.freeze

      COLOR_BY_STATUS = {
        ok: :green,
        warning: :yellow,
        fail: :red
      }.freeze

      SLUG_TO_MESSAGE = {
        missing_foreign_key: 'should have foreign key in the database',
        inconsistent_types: "foreign key %<fk_name>s with type %<fk_type>s doesn't cover primary key %<pk_name>s with type %<pk_type>s", # rubocop:disable Layout/LineLength
        has_one_missing_unique_index: 'associated model should have proper unique index in the database',
        association_missing_index: 'associated model should have proper index in the database',
        length_validator_missing: 'column has limit in the database but do not have length validator',
        length_validator_greater_limit: 'column has greater limit in the database than in length validator',
        length_validator_lower_limit: 'column has lower limit in the database than in length validator',
        null_constraint_association_misses_validator: 'column is required in the database but do not have presence validator for association %<association_name>s', # rubocop:disable Layout/LineLength
        null_constraint_misses_validator: 'column is required in the database but do not have presence validator',
        small_primary_key: 'column has int/serial type but recommended to have bigint/bigserial/uuid',
        redundant_index: 'index is redundant as %<covered_index_name>s covers it',
        redundant_unique_index: 'index uniqueness is redundant as %<covered_index_name>s covers it',
        missing_uniqueness_validation: 'index is unique in the database but do not have uniqueness validator',
        missing_unique_index: 'model should have proper unique index in the database',
        possible_null: 'column is required but there is possible null value insert',
        null_constraint_missing: 'column should be required in the database',
        association_missing_null_constraint: 'association foreign key column should be required in the database'
      }.freeze

      def write
        results.each do |result|
          next unless write?(result.status)

          puts msg(result)
        end
      end

      private

      def msg(result)
        "#{result.checker_name} #{status_text(result)} #{key_text(result)} #{message_text(result)}"
      end

      def write?(status)
        status == :fail || config.debug?
      end

      def message_text(result)
        (SLUG_TO_MESSAGE[result.error_slug] || result.error_message || '') % result.attributes
      end

      def key_text(result)
        "#{colorize(result.table_or_model_name, :blue)} #{colorize(result.column_or_attribute_name, :yellow)}"
      end

      def status_text(result)
        color = COLOR_BY_STATUS[result.status]

        colorize(result.status, color)
      end

      def colorize(text, color)
        return text unless config.colored? && color

        "#{COLORS[color]}#{text}\e[0m"
      end
    end
  end
end
