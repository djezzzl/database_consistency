# frozen_string_literal: true

module DatabaseConsistency
  module Helper
    # The `AND` clauses of a SQL predicate: which `AND`s actually join two
    # clauses, and what the clause list looks like once nested conjunctions have
    # been flattened into it.
    module AndClauses
      module_function

      # Sorts top-level clauses so `a AND b` and `b AND a` reach the same string
      # before comparison. Clauses are kept verbatim so parentheses binding an
      # `OR` survive. The block, when given, supplies the value each clause is
      # ordered by, which lets a caller order by a clause's real text while the
      # clauses themselves still carry masked literals.
      def sort(sql, &sort_key)
        return sql if top_level_or?(sql)

        clauses = split(sql)
        return sql if clauses.length == 1

        clauses.sort_by { |clause| sort_key ? sort_key.call(clause) : clause }.join(' AND ')
      end

      # `a AND b OR c` means `(a AND b) OR c`, so ordering the clauses of such a
      # predicate would move one across the `OR` and change what it means.
      # Active Record's `or` generates exactly this shape. A predicate carrying
      # one is left alone; `split` assumes a conjunction and is not asked.
      def top_level_or?(sql)
        depth = 0

        sql.scan(/[()]|\bOR\b/i) do |token|
          case token
          when '(' then depth += 1
          when ')' then depth -= 1
          else return true if depth.zero?
          end
        end

        false
      end

      # Splits on the `AND`s that actually join two clauses: one inside a
      # parenthesized group, or the one completing a `BETWEEN` range, belongs to
      # its clause instead. A group whose own top level is a conjunction is
      # flattened, so `a AND (b AND c)` and `a AND b AND c` split the same way.
      def split(sql)
        sql.split(/\s+AND\s+/i)
           .each_with_object([]) { |fragment, clauses| append_fragment(clauses, fragment) }
           .flat_map { |clause| flatten_group(clause) }
      end

      # Starts a new clause, or hands the fragment to the previous clause when
      # that one is still waiting for the rest of itself.
      def append_fragment(clauses, fragment)
        previous = clauses.pop if clauses.last && incomplete?(clauses.last)

        clauses << [previous, fragment].compact.join(' AND ')
      end

      # A clause is incomplete while it holds an unclosed parenthesis, or a
      # `BETWEEN` whose range is still missing the `AND` that ends it.
      def incomplete?(clause)
        Parentheses.unclosed?(clause) ||
          clause.scan(/\bBETWEEN\b/i).length > clause.scan(/\bAND\b/i).length
      end

      # `a AND (b AND c)` means `a AND b AND c`, so a group whose top level is a
      # conjunction is flattened into the surrounding clause list. An `OR`
      # nested deeper inside it stays in its own group and is split around.
      def flatten_group(clause)
        inner = Parentheses.strip_outer(clause)
        return [clause] if inner == clause || top_level_or?(inner)

        split(inner)
      end
    end
  end
end
