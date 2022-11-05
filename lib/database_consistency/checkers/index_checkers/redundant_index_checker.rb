# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks redundant database indexes
    class RedundantIndexChecker < IndexChecker
      class Report < DatabaseConsistency::Report # :nodoc:
        attr_reader :index_name

        def initialize(index_name:, **args)
          super(**args)
          @index_name = index_name
        end

        def attributes
          super.merge(index_name: index_name)
        end
      end

      private

      # We skip check when:
      #  - index is unique
      def preconditions
        !index.unique
      end

      # Table of possible statuses
      # | validation | status |
      # | ---------- | ------ |
      # | provided   | ok     |
      # | redundant  | fail   |
      #
      def check
        if covered_by_index
          Report.new(
            status: :fail,
            error_slug: :redundant_index,
            error_message: nil,
            index_name: covered_by_index.name,
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

            clause_equals?(another_index) && include_index_as_prefix?(another_index)
          end
      end

      def clause_equals?(another_index)
        another_index.where == index.where
      end

      def include_index_as_prefix?(another_index)
        another_index_columns = Helper.extract_index_columns(another_index.columns)
        index_columns == another_index_columns.first(index_columns.size)
      end

      def index_columns
        @index_columns ||= Helper.extract_index_columns(index.columns)
      end
    end
  end
end
