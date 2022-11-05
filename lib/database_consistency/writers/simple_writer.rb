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
        association_missing_index: 'associated model should have proper index in the database'
      }.freeze

      def write
        results.each do |result|
          next unless write?(result.status)

          puts msg(result)
        end
      end

      def msg(result)
        "#{result.checker_name} #{status_text(result)} #{key_text(result)} #{message_text(result)}"
      end

      private

      def message_text(result)
        SLUG_TO_MESSAGE[result.error_slug] % result.attributes || result.error_message
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
