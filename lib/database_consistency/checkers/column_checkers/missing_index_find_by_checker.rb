# frozen_string_literal: true

begin
  require 'prism'
rescue LoadError
  # Prism is not available; this checker will be disabled on Ruby < 3.3
end

module DatabaseConsistency
  module Checkers
    # This class checks for columns used in find_by queries that are missing a database index.
    # It uses the Prism parser (Ruby stdlib since 3.3) to traverse the AST of all project
    # source files (found by iterating loaded constants and excluding gem paths) and detect
    # calls such as find_by_<column>, find_by(column: ...) and find_by("column" => ...).
    # The checker is automatically skipped on Ruby versions where Prism is not available.
    class MissingIndexFindByChecker < ColumnChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :source_location
      )

      private

      # We skip check when:
      #  - Prism is not available (Ruby < 3.3)
      #  - column is the primary key (always indexed)
      #  - column name does not appear in any find_by call across project source files
      def preconditions
        defined?(Prism) && !primary_key_column? && find_by_used?
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

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          source_location: (status == :fail ? @find_by_location : nil),
          **report_attributes
        )
      end

      def find_by_used?
        @find_by_location = search_find_by_location
        !!@find_by_location
      end

      def search_find_by_location
        model_name = model.name.to_s
        col_name = column.name.to_s
        index = Helper.find_by_calls_index
        index.dig(model_name, col_name) || index.dig(nil, col_name)
      end

      def indexed?
        model.connection.indexes(model.table_name).any? do |index|
          Helper.extract_index_columns(index.columns).first == column.name.to_s
        end
      end

      def primary_key_column?
        column.name.to_s == model.primary_key.to_s
      end

      if defined?(Prism)
        # Prism AST visitor that collects ALL find_by calls from a source file into a results hash.
        # Key: [model_name_or_nil, column_name] — nil means bare call with no receiver.
        # Value: "file:line" location of the first matching call.
        #
        # Handles:
        #  - find_by_<col>(<value>) / Model.find_by_<col>!  (dynamic finder)
        #  - find_by(col: <value>) / Model.find_by col:     (symbol-key hash)
        #  - find_by("col" => <value>)                      (string-key hash)
        #
        # Defined only when Prism is available (Ruby 3.3+).
        class FindByCollector < Prism::Visitor
          # Matches the full column name from a dynamic finder method name.
          # e.g. find_by_email → "email", find_by_first_name → "first_name"
          # Multi-column patterns like find_by_name_and_email extract "name_and_email"
          # which won't match any single-column name, so there are no false positives.
          DYNAMIC_FINDER_RE = /\Afind_by_(.+?)!?\z/

          attr_reader :results

          def initialize(file)
            super()
            @file = file
            @results = {}
          end

          def visit_call_node(node)
            name = node.name.to_s
            if (match = DYNAMIC_FINDER_RE.match(name))
              model_key = receiver_to_model_key(node.receiver)
              store(model_key, match[1], node) unless model_key == :skip
            elsif name == 'find_by' && node.arguments
              col = single_hash_column(node.arguments)
              model_key = receiver_to_model_key(node.receiver)
              store(model_key, col, node) if col && model_key != :skip
            end
            super
          end

          private

          def store(model_key, col, node)
            @results[[model_key, col]] ||= "#{@file}:#{node.location.start_line}"
          end

          def receiver_to_model_key(receiver)
            case receiver
            when nil then nil
            when Prism::ConstantReadNode, Prism::ConstantPathNode
              constant_path_name(receiver)
            when Prism::CallNode
              scoped_receiver_model(receiver)
            else
              :skip
            end
          end

          def scoped_receiver_model(call_node)
            return :skip unless %w[unscoped includes].include?(call_node.name.to_s)

            rec = call_node.receiver
            return :skip unless rec.is_a?(Prism::ConstantReadNode) || rec.is_a?(Prism::ConstantPathNode)

            constant_path_name(rec)
          end

          def constant_path_name(node)
            case node
            when Prism::ConstantReadNode then node.name.to_s
            when Prism::ConstantPathNode then "#{constant_path_name(node.parent)}::#{node.name}"
            end
          end

          def single_hash_column(arguments_node)
            arguments_node.arguments.each do |arg|
              next unless arg.is_a?(Prism::KeywordHashNode) && arg.elements.size == 1

              assoc = arg.elements.first
              next unless assoc.is_a?(Prism::AssocNode)

              key = assoc.key
              return key.unescaped if key.is_a?(Prism::SymbolNode) || key.is_a?(Prism::StringNode)
            end
            nil
          end
        end
      end
    end
  end
end
