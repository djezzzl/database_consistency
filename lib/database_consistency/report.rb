# frozen_string_literal: true

module DatabaseConsistency
  class Report
    attr_reader :checker_name, :table_or_model_name, :column_or_attribute_name, :status, :error_slug, :error_message

    def initialize(checker_name:, table_or_model_name:, column_or_attribute_name:, status:, error_slug:, error_message:)
      @checker_name = checker_name
      @table_or_model_name = table_or_model_name
      @column_or_attribute_name = column_or_attribute_name
      @status = status
      @error_slug = error_slug
      @error_message = error_message
    end
  end
end
