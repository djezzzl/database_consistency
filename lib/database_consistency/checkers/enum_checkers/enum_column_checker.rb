# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks that ActiveRecord enum is backed by enum column
    class EnumColumnChecker < EnumChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :table_name,
        :column_name
      )

      private

      # ActiveRecord supports native enum type since version 7 and only for PostgreSQL
      def preconditions
        Helper.postgresql? && ActiveRecord::VERSION::MAJOR >= 7 && column.present?
      end

      def check
        if valid?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :enum_column_type_mismatch)
        end
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          table_name: model.table_name,
          column_name: column.name,
          **report_attributes
        )
      end

      def column
        @column ||= model.columns.find { |c| c.name.to_s == enum.to_s }
      end

      # @return [Boolean]
      def valid?
        column.type == :enum
      end
    end
  end
end
