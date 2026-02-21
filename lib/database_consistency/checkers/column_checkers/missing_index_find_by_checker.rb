# frozen_string_literal: true

require 'ripper'

module DatabaseConsistency
  module Checkers
    # This class checks for columns used in find_by queries that are missing a database index.
    # It uses Ruby's built-in Ripper library to parse model source files into an AST and
    # detect calls such as find_by_<column>, find_by(column: ...) and find_by("column" => ...).
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
        source = File.read(model_source_file)
        sexp = Ripper.sexp(source)
        return false unless sexp

        find_by_column_in_sexp?(sexp, column.name.to_s)
      end

      # Recursively traverse the Ripper AST looking for find_by calls referencing the column.
      # Handles two kinds of Array nodes:
      #   - Named nodes: [:type, child, ...] where type is a Symbol
      #   - Statement lists: [node, node, ...] where elements are named nodes
      def find_by_column_in_sexp?(node, col)
        return false unless node.is_a?(Array)
        return false if node.empty?

        if node[0].is_a?(Symbol)
          return true if find_by_node_matches?(node, col)

          node[1..].any? { |child| find_by_column_in_sexp?(child, col) }
        else
          node.any? { |child| find_by_column_in_sexp?(child, col) }
        end
      end

      # Check whether a single AST node is a find_by call targeting the column.
      def find_by_node_matches?(node, col) # rubocop:disable Metrics/MethodLength
        case node[0]
        when :method_add_arg
          # receiver.method(args) or method(args)
          call_node, args_node = node[1], node[2]
          method_name = extract_method_name(call_node)
          return true if dynamic_find_by?(method_name, col)

          method_name == 'find_by' && hash_args_include_column?(args_node, col)
        when :call
          # receiver.method — no explicit args node (e.g. find_by_email!)
          dynamic_find_by?(extract_method_name(node), col)
        when :vcall
          # method — no receiver, no args (e.g. bare find_by_email)
          dynamic_find_by?(extract_method_name(node), col)
        when :command
          # find_by key: val — no receiver, no parentheses
          method_name = extract_ident(node[1])
          method_name == 'find_by' && hash_args_include_column?(node[2], col)
        when :command_call
          # receiver.find_by key: val — with receiver, no parentheses
          method_name = extract_ident(node[3])
          method_name == 'find_by' && hash_args_include_column?(node[4], col)
        else
          false
        end
      end

      def dynamic_find_by?(method_name, col)
        method_name == "find_by_#{col}" || method_name == "find_by_#{col}!"
      end

      # Extract the string method name from a :call, :fcall, or :vcall node.
      def extract_method_name(node)
        return unless node.is_a?(Array)

        ident = case node[0]
                when :call          then node[3]
                when :fcall, :vcall then node[1]
                end
        extract_ident(ident)
      end

      # Return the identifier string from a [:@ident, "name", ...] leaf node.
      def extract_ident(node)
        node[1] if node.is_a?(Array) && node[0] == :@ident
      end

      # Recursively check whether an argument AST subtree contains a hash key matching col.
      def hash_args_include_column?(node, col)
        return false unless node.is_a?(Array)
        return false if node.empty?

        if node[0].is_a?(Symbol)
          if node[0] == :assoc_new
            key = node[1]
            return true if symbol_label_key?(key, col) || string_literal_key?(key, col)
          end
          node[1..].any? { |child| hash_args_include_column?(child, col) }
        else
          node.any? { |child| hash_args_include_column?(child, col) }
        end
      end

      # Match symbol-style key: [:@label, "col:", ...]
      def symbol_label_key?(key, col)
        key.is_a?(Array) && key[0] == :@label && key[1].to_s.chomp(':') == col
      end

      # Match string-style key: [:string_literal, [:string_content, [:@tstring_content, "col", ...]]]
      def string_literal_key?(key, col)
        key.is_a?(Array) &&
          key[0] == :string_literal &&
          key[1].is_a?(Array) && key[1][0] == :string_content &&
          key[1][1].is_a?(Array) && key[1][1][0] == :@tstring_content &&
          key[1][1][1] == col
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
