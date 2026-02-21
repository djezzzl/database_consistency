# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks for columns used in find_by queries that are missing a database index
    class MissingIndexFindByChecker < ColumnChecker
      private

      # We skip check when:
      #  - column is the primary key (always indexed)
      #  - model source file cannot be determined
      #  - column name does not appear in any find_by call in the model source
      def preconditions
        !primary_key_column? && model_source_file && find_by_used?
      end

      # Table of possible statuses
      # | index    | status |
      # | -------- | ------ |
      # | present  | ok     |
      # | missing  | fail   |
      def check
        if indexed?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :missing_index_find_by)
        end
      end

      def find_by_used?
        col = Regexp.escape(column.name.to_s)
        source = File.read(model_source_file)

        # Dynamic finder: find_by_column_name or find_by_column_name!
        source.match?(/find_by_#{col}(\b|!)/) ||
          # Hash-style: find_by(column: ...) or find_by column:
          source.match?(/find_by[(\s]\s*#{col}:/) ||
          # String-key style: find_by("column" => ...) or find_by('column' => ...)
          source.match?(/find_by[(\s]\s*['"]#{col}['"]\s*=>/)
      end

      def indexed?
        model.connection.indexes(model.table_name).any? do |index|
          Helper.extract_index_columns(index.columns).include?(column.name.to_s)
        end
      end

      def primary_key_column?
        column.name.to_s == model.primary_key.to_s
      end

      def model_source_file
        @model_source_file ||= find_model_source_file
      end

      def find_model_source_file
        return unless Module.respond_to?(:const_source_location)

        file, = Module.const_source_location(model.name)
        file if file && File.exist?(file)
      rescue NameError
        nil
      end
    end
  end
end
