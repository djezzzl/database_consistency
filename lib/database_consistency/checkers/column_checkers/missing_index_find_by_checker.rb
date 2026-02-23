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

      def find_by_used?
        model_name = model.name.to_s
        Helper.project_source_files.any? do |file|
          result = Prism.parse(File.read(file))
          visitor = FindByVisitor.new(column.name.to_s, model_name)
          visitor.visit(result.value)
          visitor.found?
        end
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
        # Prism AST visitor that detects find_by calls referencing a specific column.
        # Handles:
        #  - find_by_<col>(<value>) / Model.find_by_<col>!  (dynamic finder)
        #  - find_by(col: <value>) / Model.find_by col:     (symbol-key hash)
        #  - find_by("col" => <value>)                      (string-key hash)
        #
        # Defined only when Prism is available; otherwise this constant does not exist and
        # the checker's preconditions guard (defined?(Prism)) prevents it from being used.
        class FindByVisitor < Prism::Visitor
          attr_reader :found

          alias found? found

          def initialize(column_name, model_name)
            super()
            @column_name = column_name
            @model_name = model_name
            @found = false
          end

          def visit_call_node(node)
            name = node.name.to_s

            if ["find_by_#{@column_name}", "find_by_#{@column_name}!"].include?(name)
              @found = true if valid_receiver?(node.receiver)
            elsif name == 'find_by' && node.arguments
              @found = true if valid_receiver?(node.receiver) && find_by_hash_includes_column?(node.arguments)
            end

            super
          end

          private

          def valid_receiver?(receiver)
            case receiver
            when nil then true
            when Prism::ConstantReadNode, Prism::ConstantPathNode
              constant_path_name(receiver) == @model_name
            when Prism::CallNode then allowed_scoped_receiver?(receiver)
            else false
            end
          end

          def allowed_scoped_receiver?(call_node)
            return false unless %w[unscoped includes].include?(call_node.name.to_s)

            rec = call_node.receiver
            (rec.is_a?(Prism::ConstantReadNode) || rec.is_a?(Prism::ConstantPathNode)) &&
              constant_path_name(rec) == @model_name
          end

          def constant_path_name(node)
            case node
            when Prism::ConstantReadNode then node.name.to_s
            when Prism::ConstantPathNode then "#{constant_path_name(node.parent)}::#{node.name}"
            end
          end

          def find_by_hash_includes_column?(arguments_node)
            arguments_node.arguments.any? do |arg|
              next unless arg.is_a?(Prism::KeywordHashNode)
              next unless arg.elements.size == 1

              assoc = arg.elements.first
              next unless assoc.is_a?(Prism::AssocNode)

              assoc_key_matches?(assoc.key)
            end
          end

          def assoc_key_matches?(key)
            case key
            when Prism::SymbolNode then key.unescaped == @column_name
            when Prism::StringNode then key.unescaped == @column_name
            else false
            end
          end
        end
      end
    end
  end
end
