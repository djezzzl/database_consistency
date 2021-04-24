# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks redundant database indexes
    class RedundantUniqueIndexChecker < IndexChecker
      # Message templates
      REDUNDANT_UNIQUE_INDEX = 'index uniqueness is redundant as (%index) covers it'

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
      def check
        if covered_by_index
          report_template(:fail, render_message)
        else
          report_template(:ok)
        end
      end

      def render_message
        REDUNDANT_UNIQUE_INDEX.sub('%index', covered_by_index.name)
      end

      def covered_by_index
        @covered_by_index ||=
          model.connection.indexes(model.table_name).find do |another_index|
            next if index.name == another_index.name

            another_index.unique && contain_index?(another_index)
          end
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
