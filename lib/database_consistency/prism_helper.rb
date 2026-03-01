# frozen_string_literal: true

module DatabaseConsistency
  # The module contains Prism AST helper methods for scanning project source files.
  module PrismHelper
    module_function

    # Returns a memoized index: {model_name => {column_name => "file:line"}}.
    # Built once per run by scanning all project source files with Prism (Ruby 3.3+).
    # Bare find_by calls are resolved to their lexical class/module scope.
    def find_by_calls_index
      return {} unless defined?(Prism)

      @find_by_calls_index ||= build_find_by_calls_index
    end

    def build_find_by_calls_index
      FilesHelper.project_source_files.each_with_object({}) do |file, index|
        collector = Checkers::MissingIndexFindByChecker::FindByCollector.new(file)
        collector.visit(Prism.parse_file(file).value)
        merge_collector_results(collector.results, index)
      rescue StandardError
        nil
      end
    end

    def merge_collector_results(results, index)
      results.each do |(model_key, col), locations|
        index[model_key] ||= {}
        if (entry = index[model_key][col])
          entry[:total_findings_count] += locations.size
        else
          index[model_key][col] = { first_location: locations.first, total_findings_count: locations.size }
        end
      end
    end
  end
end
