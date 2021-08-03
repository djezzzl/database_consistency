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

      def write
        results.each do |result|
          next unless write?(result.status)

          puts msg(result)
        end
      end

      def msg(result)
        "#{result.checker_name} #{status_text(result)} #{key_text(result)} #{result.message}"
      end

      private

      def key_text(result)
        "#{colorize(result.table_or_model_name, :blue)} #{colorize(result.column_or_attribute_name, :yellow)}"
      end

      def status_text(result)
        color = case result.status
                when :ok then :green
                when :warning then :yellow
                when :fail then :red
                end

        colorize(result.status, color)
      end

      def colorize(text, color)
        return text unless config.colored? && color

        "#{COLORS[color]}#{text}\e[0m"
      end
    end
  end
end
