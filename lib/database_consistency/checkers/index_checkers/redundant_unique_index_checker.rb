# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks redundant database indexes
    class RedundantUniqueIndexChecker < IndexChecker
      class Report < DatabaseConsistency::Report # :nodoc:
        attr_reader :index_name, :covered_index_name

        def initialize(covered_index_name:, index_name:, **args)
          super(**args)
          @index_name = index_name
          @covered_index_name = covered_index_name
        end
      end

      private

      # We skip check when:
      #  - index is not unique
      def preconditions
        index.unique
      end

      # Table of possible statuses
      # | validation | status |
      # | ---------- | ------ |
      # | provided   | ok     |
      # | redundant  | fail   |
      #
      def check # rubocop:disable Metrics/MethodLength
        if covered_by_index
          Report.new(
            status: :fail,
            error_slug: :redundant_unique_index,
            error_message: nil,
            index_name: index.name,
            covered_index_name: covered_by_index.name,
            **report_attributes
          )
        else
          report_template(:ok)
        end
      end

      def covered_by_index
        @covered_by_index ||=
          model.connection.indexes(model.table_name).find do |another_index|
            next if index.name == another_index.name

            another_index.unique && clause_equals?(another_index) && contain_index?(another_index)
          end
      end

      def clause_equals?(another_index)
        another_index.where == index.where
      end

      def contain_index?(another_index)
        another_index_columns = Helper.extract_index_columns(another_index.columns)
        index_columns & another_index_columns == another_index_columns
      end

      def index_columns
        @index_columns ||= Helper.extract_index_columns(index.columns)
      end
    end
  end
end
