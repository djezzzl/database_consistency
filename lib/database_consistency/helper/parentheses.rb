# frozen_string_literal: true

module DatabaseConsistency
  module Helper
    # Parenthesis bookkeeping for SQL predicates: what a pair of parentheses
    # encloses, and whether a fragment is still waiting for one to close.
    module Parentheses
      module_function

      # Repeatedly removes one wrapping layer when the whole fragment is
      # enclosed, e.g. `((foo))` -> `foo`.
      def strip_outer(sql)
        stripped_sql = sql.strip

        stripped_sql = stripped_sql[1..-2].strip while wrapping?(stripped_sql)

        stripped_sql
      end

      # Returns true only when one outer pair encloses the whole string, not
      # when that parenthesis closes earlier inside the expression.
      def wrapping?(sql)
        return false unless sql.start_with?('(') && sql.end_with?(')')

        depth = 0

        sql[1..-2].each_char do |char|
          depth = depth_after(depth, char)
          return false if depth.negative?
        end

        depth.zero?
      end

      # Returns true while the fragment opens a group it never closes.
      def unclosed?(sql)
        sql.count('(') > sql.count(')')
      end

      # Tracks nesting depth character by character.
      def depth_after(depth, char)
        case char
        when '('
          depth + 1
        when ')'
          depth - 1
        else
          depth
        end
      end
    end
  end
end
