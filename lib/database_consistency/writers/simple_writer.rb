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
        "#{result.status} #{result.table_or_model_name} #{result.column_or_attribute_name} #{result.message}".tap do |s|
          s.concat " (checker: #{result.checker_name})" if debug?
        end
      end
    end
  end
end
