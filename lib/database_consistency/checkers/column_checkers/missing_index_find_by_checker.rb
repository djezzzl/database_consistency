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
        project_source_files.any? do |file|
          result = Prism.parse(File.read(file))
          visitor = FindByVisitor.new(column.name.to_s)
          visitor.visit(result.value)
          visitor.found?
        end
      end

      def project_source_files
        return [] unless Module.respond_to?(:const_source_location)

        files = []
        ObjectSpace.each_object(Module) do |mod|
          file = source_file_for(mod)
          files << file if file
        end
        files.uniq
      end

      def source_file_for(mod)
        name = mod.name
        return unless name

        file, = Module.const_source_location(name)
        return unless file && File.exist?(file)
        return if defined?(Bundler) && file.include?(Bundler.bundle_path.to_s)

        file
      rescue NameError
        nil
      end

      def indexed?
        model.connection.indexes(model.table_name).any? do |index|
          Helper.extract_index_columns(index.columns).include?(column.name.to_s)
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

          def initialize(column_name)
            super()
            @column_name = column_name
            @found = false
          end

          def visit_call_node(node)
            name = node.name.to_s

            if ["find_by_#{@column_name}", "find_by_#{@column_name}!"].include?(name)
              @found = true
            elsif name == 'find_by' && node.arguments
              @found = true if find_by_hash_includes_column?(node.arguments)
            end

            super
          end

          private

          def find_by_hash_includes_column?(arguments_node)
            arguments_node.arguments.any? do |arg|
              next unless arg.is_a?(Prism::KeywordHashNode)

              arg.elements.any? do |assoc|
                next unless assoc.is_a?(Prism::AssocNode)

                assoc_key_matches?(assoc.key)
              end
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
