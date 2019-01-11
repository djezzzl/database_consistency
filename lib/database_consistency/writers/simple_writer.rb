# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      def write
        puts format
      end

      def format
        results.map do |result|
          next unless write?(result[:status])

          line(result)
        end.tap(&:compact!).map(&:lstrip).delete_if(&:empty?).join("\n")
      end

      def line(result)
        s = "#{result.status} #{result.table_or_model_name} #{result.column_or_attribute_name} #{result.message}"
        s += " (checker: #{result.checker_name})" if debug?
        s
      end
    end
  end
end
