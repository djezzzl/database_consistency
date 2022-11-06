# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The writer that generates to-do file
    class TodoWriter < BaseWriter
      def write
        h = results.each_with_object({}) do |result, hash|
          next unless write?(result.status)

          assign_result(hash, result)
        end

        File.write(file_name, h.to_yaml)
      end

      private

      def write?(status)
        status == :fail
      end

      def assign_result(hash, result)
        hash[result.table_or_model_name] ||= {}
        hash[result.table_or_model_name][result.column_or_attribute_name] ||= {}
        hash[result.table_or_model_name][result.column_or_attribute_name][result.checker_name] = { 'enabled' => false }
      end

      def file_name
        [nil, *(1..100)].each do |number|
          name = generate_file_name(number)

          return name unless File.exist?(name)
        end
      end

      def generate_file_name(number = nil)
        ".database_consistency.todo#{number}.yml"
      end
    end
  end
end
