# frozen_string_literal: true

module DatabaseConsistency
  # The module contains helper methods
  module Helper # rubocop:disable Metrics/ModuleLength
    module_function

    def adapter
      if ActiveRecord::Base.respond_to?(:connection_db_config)
        ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
      else
        ActiveRecord::Base.connection_config[:adapter]
      end
    end

    def database_name(model)
      model.connection_db_config.name.to_s if model.respond_to?(:connection_db_config)
    end

    def postgresql?
      adapter == 'postgresql'
    end

    def connection_config(klass)
      if klass.respond_to?(:connection_db_config)
        klass.connection_db_config.configuration_hash
      else
        klass.connection_config
      end
    end

    def project_models(configuration)
      ActiveRecord::Base.descendants.select do |klass|
        next unless configuration.model_enabled?(klass)

        project_klass?(klass) && connected?(klass)
      end
    end

    # Returns list of models to check
    def models(configuration)
      project_models(configuration).select do |klass|
        !klass.abstract_class? &&
          klass.table_exists? &&
          !klass.name.include?('HABTM_')
      end
    end

    def connected?(klass)
      klass.connection
    rescue ActiveRecord::ConnectionNotEstablished
      puts "#{klass} does not have an active connection, skipping"
      false
    end

    # Return list of not inherited models
    def parent_models(configuration)
      models(configuration).group_by(&:table_name).each_value.flat_map do |models|
        models.reject { |model| models.include?(model.superclass) }
      end
    end

    # @param klass [ActiveRecord::Base]
    #
    # @return [Boolean]
    def project_klass?(klass)
      return true unless Module.respond_to?(:const_source_location) && defined?(Bundler)

      !Module.const_source_location(klass.to_s).first.to_s.include?(Bundler.bundle_path.to_s)
    rescue NameError
      false
    end

    # @return [Boolean]
    def check_inclusion?(array, element)
      array.include?(element.to_s) || array.include?(element.to_sym)
    end

    def first_level_associations(model)
      associations = model.reflect_on_all_associations

      while model != ActiveRecord::Base && model.respond_to?(:reflect_on_all_associations)
        model = model.superclass
        associations -= model.reflect_on_all_associations
      end

      associations
    end

    # @return [Array<String>]
    def extract_index_columns(index_columns)
      return index_columns unless index_columns.is_a?(String)

      index_columns.split(',')
                   .map(&:strip)
                   .map { |str| str.gsub(/lower\(/i, 'lower(') }
                   .map { |str| str.gsub(/\(([^)]+)\)::\w+/, '\1') }
                   .map { |str| str.gsub(/'([^)]+)'::\w+/, '\1') }
    end

    def sorted_uniqueness_validator_columns(attribute, validator, model)
      uniqueness_validator_columns(attribute, validator, model).sort
    end

    def uniqueness_validator_columns(attribute, validator, model)
      ([wrapped_attribute_name(attribute, validator, model)] + scope_columns(validator, model)).map(&:to_s)
    end

    def scope_columns(validator, model)
      Array.wrap(validator.options[:scope]).map do |scope_item|
        foreign_key_or_attribute(model, scope_item)
      end
    end

    def inclusion_validator_values(validator)
      value = validator.options[:in]

      if value.is_a?(Proc) && value.arity.zero?
        value.call
      else
        Array.wrap(value)
      end
    end

    def btree_index?(index)
      (index.type.nil? || index.type.to_s == 'btree') &&
        (index.using.nil? || index.using.to_s == 'btree')
    end

    def extract_columns(str)
      case str
      when Array
        str.map(&:to_s)
      when String
        str.scan(/(\w+)/).flatten
      when Symbol
        [str.to_s]
      else
        raise "Unexpected type for columns: #{str.class} with value: #{str}"
      end
    end

    def foreign_key_or_attribute(model, attribute)
      model._reflect_on_association(attribute)&.foreign_key || attribute
    end

    # Returns the normalized WHERE SQL produced by a conditions proc, or nil if
    # it cannot be determined (complex proc, unsupported AR version, etc.).
    def conditions_where_sql(model, conditions)
      sql = model.unscoped.instance_exec(&conditions).to_sql
      where_part = sql.split(/\bWHERE\b/i, 2).last
      return nil unless where_part

      normalize_condition_sql(where_part.gsub("#{model.quoted_table_name}.", ''))
    rescue StandardError
      nil
    end

    # Builds the effective uniqueness constraint enforced by a validator.
    #
    # When the validator carries an explicit `conditions` proc, that proc is the
    # authoritative partial predicate. The implicit `allow_nil` / `allow_blank`
    # guard on the validated attribute is redundant against a unique index (which
    # already treats NULLs as distinct), so it is only used as a fallback when no
    # explicit conditions are present. Otherwise gems that always set `allow_nil`
    # (e.g. database_validations) would append a duplicate or extra
    # `attribute IS NOT NULL` clause and never match the partial index.
    def uniqueness_validator_where_sql(model, attribute, validator)
      conditions_sql = conditions_where_sql(model, validator.options[:conditions])
      guard_sql = conditions_sql ? nil : uniqueness_validator_guard_sql(model, attribute, validator)

      sql_parts = [conditions_sql, guard_sql].reject { |part| part.nil? || part == '' }
      return nil if sql_parts.empty?

      normalize_condition_sql(sql_parts.join(' AND '))
    end

    # Returns true when validator conditions and index WHERE clause are a valid
    # pairing: both absent means a match; exactly one present means no match;
    # when both present the normalized SQL is compared.
    def conditions_match_index?(model, attribute, validator, index_where)
      validator_where = uniqueness_validator_where_sql(model, attribute, validator)
      return true if validator_where.nil? && index_where.blank?
      return true if index_where.blank? && validator_guard_only?(model, attribute, validator)
      return false if validator_where.nil? || index_where.blank?

      normalized_where = normalize_condition_sql(index_where)
      validator_where.casecmp?(normalized_where)
    end

    # Prefix used to mask string literals while regex normalization runs, so
    # patterns that strip casts or unwrap parentheses never see the inside of a
    # literal value. Angle brackets are used so the placeholder cannot be mistaken
    # for a column name by the boolean-predicate normalizer.
    LITERAL_PLACEHOLDER = '__DATABASE_CONSISTENCY_LITERAL<%<index>d>__'

    # Matches one single-quoted string literal, including any `''` it contains:
    # SQL escapes a quote by doubling it, so a `''` pair is part of the value
    # rather than the end of it.
    CONDITION_LITERAL = /'(?:[^']|'')*'/.freeze

    # Matches a masked literal, so steps that run on masked SQL can step over
    # the `<` and `>` in the placeholder.
    MASKED_LITERAL = Regexp.new(
      Regexp.escape(LITERAL_PLACEHOLDER).sub('%<index>d') { '\d+' }
    ).freeze

    # Matches an operator together with whatever spaces were written around it.
    # `+` and `-` are left out: either can be a sign as well as an operator, and
    # telling the two apart takes a parser. `->` and `->>` are the exception,
    # since neither can be read as a sign.
    CONDITION_OPERATOR = %r{\s*(->>?|[<>=!~@#%^&|?*/]+)\s*}.freeze

    # Matches either of the two, so the spacing step can find operators while
    # passing over the placeholders.
    MASKED_LITERAL_OR_OPERATOR = Regexp.union(MASKED_LITERAL, CONDITION_OPERATOR).freeze

    # Matches a number PostgreSQL had to quote in order to coerce it, together
    # with the cast that says it is a number rather than a string. `::text` is
    # deliberately absent from the list so a genuine string keeps its quotes.
    COERCED_NUMERIC_LITERAL = /
      ' (-? \d+ (?:\.\d+)? (?: e[+-]?\d+ )? ) '
      (?= :: (?: integer | bigint | numeric | double\s+precision ) \b )
    /xi.freeze

    # Matches a PostgreSQL cast, covering the type names written as several
    # words, the length or precision an explicit cast carries and the `[]` of an
    # array type: `::text`, `::text[]`, `::double precision`,
    # `::character varying(3)`, `::numeric(5,2)`, `::time without time zone`.
    # A date or time type carries its precision in the middle of its name, as
    # `::timestamp(0) without time zone`, so that branch spells out its own.
    CONDITION_CAST = /
      ::
      (?:
        character\s+varying |
        double\s+precision |
        bit\s+varying |
        (?:timestamp|time) (?:\(\d+\))? \s+ (?:with|without)\s+time\s+zone |
        \w+
      )
      (?:\(\d+(?:\s*,\s*\d+)?\))?
      (?:\[\])?
    /xi.freeze

    # Matches a number written in exponent notation, capturing the sign, the
    # digits on each side of the decimal point and the exponent separately so
    # the point can be shifted through the digits as text. The lookbehind keeps
    # the digits of an identifier such as `a1e5` out of it.
    EXPONENT_LITERAL = /
      (?<![\w.])
      (-?) (\d+) (?: \.(\d+) )? e ([+-]?\d+)
    /xi.freeze

    # The parentheses right after `IN` or `NOT IN` are the list itself rather
    # than something wrapped around a value, so the patterns below leave them
    # alone and `qty IN (1)` stays a list of one. This covers only the
    # parenthesis that opens the list; a value with parentheses of its own
    # further along it, such as the `(1)` in `qty IN ((1), 2)`, still loses
    # them.
    IN_LIST_OPENING = /(?<!\bIN\s)/i.freeze

    # Matches a bare identifier wrapped in parentheses, e.g. `(internal_name)`.
    # The lookbehind keeps the argument list of a call such as `lower(name)`
    # intact.
    WRAPPED_IDENTIFIER = /(?<![\w.])#{IN_LIST_OPENING}\(([a-z_][\w.]*)\)/i.freeze

    # Matches a parenthesized numeric literal, e.g. `(0)` or `(0.001)`, which is
    # what a cast such as `(0)::numeric` leaves behind once the cast is gone.
    # The lookbehind keeps the argument list of a call such as `abs(1)` intact.
    WRAPPED_NUMBER = /(?<![\w.])#{IN_LIST_OPENING}\((-?\d+(?:\.\d+)?(?:e-?\d+)?)\)/.freeze

    # Matches parentheses wrapping exactly one function call, such as the
    # `(abs(1))` a removed `::numeric` cast leaves behind. The inner group
    # recurses so the call's own argument list may nest, and the lookbehind
    # keeps a call's own parentheses out of it.
    WRAPPED_FUNCTION_CALL = /
      (?<![\w.]) #{IN_LIST_OPENING}
      \( (?<call>[a-z_][\w.]* (?<arguments>\( (?:[^()] | \g<arguments>)* \)) ) \)
    /xi.freeze

    # Matches a bare negated boolean predicate such as `NOT archived`, in the
    # three places one can stand: at the start of an expression, after `AND` or
    # `OR`, or after an opening parenthesis. The whitespace before whatever
    # follows sits inside the lookahead, so the match leaves it in place instead
    # of consuming it and fusing the next `AND` / `OR` to the rewritten
    # predicate. The lookbehind keeps a call's own parenthesis out of the
    # boolean positions, so the argument of `lower(...)` is not read as a
    # predicate of its own.
    NEGATED_BOOLEAN_PREDICATE = /
      (^ | (?: \bAND\b | \bOR\b | (?<![\w.]) \( ))
      \s* NOT \s+ ([a-z_][\w.]*)
      (?= \s* (?: $ | \bAND\b | \bOR\b | \) ))
    /xi.freeze

    # Matches a bare boolean predicate such as `most_recent` in those same three
    # places, with the same lookahead and lookbehind. It runs after the negated
    # form so that `NOT archived` is already gone and cannot be read as the
    # predicate `archived`.
    BARE_BOOLEAN_PREDICATE = /
      (^ | (?: \bAND\b | \bOR\b | (?<![\w.]) \( ))
      \s* ([a-z_][\w.]*)
      (?= \s* (?: $ | \bAND\b | \bOR\b | \) ))
    /xi.freeze

    # Matches `column = ANY (ARRAY[...])` or `column != ALL ((ARRAY[...]))`,
    # capturing the column name, the operator and the array payload. The inner
    # parentheses come from Postgres indexdefs that wrap the array expression
    # before casting; they are optional, but both or neither, so a group
    # enclosing the whole predicate keeps its own.
    ARRAY_MEMBERSHIP_PREDICATE = /
      (?<column>[a-z_][\w.]*)\s*
      (?<operator>=\s*ANY|(?:!=|<>)\s*ALL)\s*
      \( (?: \(ARRAY\[(?<items>.*?)\]\) | ARRAY\[(?<items>.*?)\] ) \)
    /xi.freeze

    # Matches SQL like `NOT (column = '' OR column IS NULL)`, holding both sides
    # to the same column with the backreference.
    NEGATED_BLANK_OR_NIL_PREDICATE = /
      NOT \s+ \( \s* \(?
      ([a-z_][\w.]*) \s* = \s* '' \s+ OR \s+ \1 \s+ IS \s+ NULL
      \)? \s* \)
    /xi.freeze

    # Normalizes SQL predicates into a canonical form so semantically equivalent
    # Rails validators and database partial indexes can be compared safely.
    def normalize_condition_sql(sql)
      # The two steps that read the inside of a literal run first, while it is
      # still there to read. Everything after masking works on the shape of the
      # predicate alone and so cannot rewrite a value by accident.
      masked_sql, literals = sql.to_s
                                .then { |value| unquote_numeric_literals(value) }
                                .then { |value| normalize_quoted_boolean_literals(value) }
                                .then { |value| mask_condition_literals(value) }

      normalize_masked_condition_sql(
        masked_sql.then { |value| strip_outer_parentheses(value) }
                  .then { |value| normalize_boolean_and_null_keywords(value) },
        literals
      )
    end

    # Finishes normalization after string literals have been masked: runs the
    # regex-based transforms that must not see inside literals, applies the
    # final structural clean-ups, and only then restores the literal values.
    # Restoring last protects literal contents from whitespace collapse and
    # clause sorting.
    def normalize_masked_condition_sql(masked_sql, literals)
      masked_sql
        .then { |value| normalize_adapter_syntax(value) }
        .then { |value| normalize_boolean_predicates(value) }
        .then { |value| normalize_array_any_predicates(value) }
        .then { |value| normalize_negated_blank_or_nil_predicates(value) }
        .then { |value| sort_and_clauses(value, literals) }
        .then { |value| value.gsub(/\s+/, ' ').strip }
        .then { |value| unmask_condition_literals(value, literals) }
    end

    # Masks non-empty string literals so later regexes cannot rewrite their
    # contents. Empty literals are left untouched because negated-blank
    # normalization relies on them.
    def mask_condition_literals(sql)
      literals = []
      masked_sql = sql.gsub(CONDITION_LITERAL) do |match|
        if match == "''"
          match
        else
          literals << match
          format(LITERAL_PLACEHOLDER, index: literals.length - 1)
        end
      end
      [masked_sql, literals]
    end

    # Restores literals in the order they were masked. Uses a block replacement
    # so backslashes inside the literal are not interpreted as regexp backrefs.
    def unmask_condition_literals(sql, literals)
      literals.each_with_index do |literal, index|
        sql = sql.sub(format(LITERAL_PLACEHOLDER, index: index)) { literal }
      end
      sql
    end

    # PostgreSQL writes any literal it had to coerce as a quoted string with a
    # cast: `-1` becomes `'-1'::integer`, `-1.5` becomes `'-1.5'::numeric` and
    # `1e+20` becomes `'1e+20'::double precision`. Unquoting those lets them line
    # up with the bare numbers Active Record generates. A `::text` cast is left
    # alone so a genuine string comparison keeps its quotes.
    def unquote_numeric_literals(sql)
      sql.gsub(COERCED_NUMERIC_LITERAL) { Regexp.last_match(1) }
    end

    # Rewrites a boolean written as the quoted `'t'` / `'f'` PostgreSQL stores.
    # It reads the value inside the quotes, so it has to run before literals are
    # masked, while that value is still there to read.
    def normalize_quoted_boolean_literals(sql)
      # Normalize PostgreSQL boolean literals stored as `'t'` / `'f'` inside
      # comparisons. The operator is allowed to touch or be surrounded by
      # arbitrary whitespace so forms like `flag='t'` and `flag  <>   'f'` all
      # collapse to the same canonical shape. Inequality is preserved as `!=`
      # because `flag <> 't'` is not the same as `flag = 'f'` (NULL handling
      # differs), so they must not share a canonical form. The lookbehind holds
      # the equality patterns to a standalone `=`, so the ordering comparison in
      # `note >= 't'` keeps both its operator and its value.
      sql
        .gsub(/(?<![<>!])\s*=\s*'t'/, ' = 1')
        .gsub(/(?<![<>!])\s*=\s*'f'/, ' = 0')
        .gsub(/\s*<>\s*'t'/, ' != 1')
        .gsub(/\s*<>\s*'f'/, ' != 0')
        .gsub(/\s*!=\s*'t'/, ' != 1')
        .gsub(/\s*!=\s*'f'/, ' != 0')
    end

    # Rewrites the `TRUE` / `FALSE` / `NULL` keywords and the `IS` phrasings
    # around them to one spelling. These run once literals are masked, so a
    # value that happens to read `IS TRUE` keeps its own text.
    def normalize_boolean_and_null_keywords(sql)
      normalized_sql = sql.dup
      # `IS NOT TRUE` / `IS NOT FALSE` are matched before the bare `IS TRUE` /
      # `IS FALSE` forms so the longer phrase wins. They normalize to `IS NOT 1`
      # / `IS NOT 0` rather than `= 0` / `= 1` because `IS NOT TRUE` is not the
      # same as `= FALSE` (NULL handling differs).
      normalized_sql = normalized_sql.gsub(/\bIS\s+NOT\s+TRUE\b/i, ' IS NOT 1')
      normalized_sql = normalized_sql.gsub(/\bIS\s+NOT\s+FALSE\b/i, ' IS NOT 0')
      # `/\bIS\s+TRUE\b/i` and `/\bIS\s+FALSE\b/i` normalize predicate forms
      # like `flag IS TRUE` to `flag = 1` so they match `flag = TRUE` and
      # `flag = 't'`.
      normalized_sql = normalized_sql.gsub(/\bIS\s+TRUE\b/i, ' = 1')
      normalized_sql = normalized_sql.gsub(/\bIS\s+FALSE\b/i, ' = 0')
      # `/\bTRUE\b/i` and `/\bFALSE\b/i` normalize boolean literals to `1` / `0`
      # so they match SQL generated by Active Record on some adapters.
      normalized_sql = normalized_sql.gsub(/\bTRUE\b/i, '1').gsub(/\bFALSE\b/i, '0')
      # `/\bIS\s+NOT\s+NULL\b/i` normalizes `IS NOT NULL` spacing and casing.
      normalized_sql = normalized_sql.gsub(/\bIS\s+NOT\s+NULL\b/i, ' IS NOT NULL')
      # `/\bIS\s+NULL\b/i` normalizes `IS NULL` spacing and casing.
      normalized_sql = normalized_sql.gsub(/\bIS\s+NULL\b/i, ' IS NULL')
      normalized_sql.gsub(/\s+/, ' ').strip
    end

    # Rewrites exponent notation as the plain decimal PostgreSQL itself writes
    # when it expands a literal, so `1e+20` and the `1.0e+20` Active Record
    # generates reach the same string. The digits are shifted as text rather
    # than through a float, so a wide value keeps every one of them.
    def expand_exponent_literals(sql)
      sql.gsub(EXPONENT_LITERAL) do
        match = Regexp.last_match
        shift_decimal_point(match[1], "#{match[2]}#{match[3]}", match[2].length + match[4].to_i)
      end
    end

    # Places the decimal point `position` digits into `digits`, padding with
    # zeros on whichever side falls short and dropping a fraction that ends in
    # them, so `1e-20` and `1.0e-20` land on the same digits. A zero that only
    # holds the decimal point's place goes too, so `0.1e+2` reaches `10`.
    def shift_decimal_point(sign, digits, position)
      expanded =
        if position >= digits.length
          digits + ('0' * (position - digits.length))
        elsif position.positive?
          "#{digits[0...position]}.#{digits[position..]}"
        else
          "0.#{'0' * -position}#{digits}"
        end
      # On Ruby < 3.0, frozen strings forbid `sub!`.
      expanded = expanded.sub(/\A0+(?=\d)/, '')

      "#{sign}#{expanded}".sub(/(\.\d*?)0+\z/, '\1').chomp('.')
    end

    # Gives every operator a space either side, every comma a space after it
    # and no parenthesis a space on its inside, which is how PostgreSQL writes
    # an indexdef however the index was typed.
    def normalize_operator_spacing(sql)
      spaced_sql = sql.gsub(MASKED_LITERAL_OR_OPERATOR) do |match|
        match.match?(MASKED_LITERAL) ? match : " #{match.strip} "
      end
      spaced_sql = spaced_sql.gsub(/\s*,\s*/, ', ')
      spaced_sql.gsub(/\(\s+/, '(').gsub(/\s+\)/, ')')
    end

    # Rewrites the spellings that differ between adapters, or between what an
    # adapter stores and what Active Record writes: quoted identifiers, casts,
    # exponent notation, the spacing of an `IN` list, of operators and of
    # commas, the parentheses PostgreSQL adds around a cast operand and the `<>`
    # it writes for inequality. Literals are masked throughout, so none of it
    # reaches the inside of a value.
    def normalize_adapter_syntax(sql)
      # Strips quoted identifiers (double quotes on PostgreSQL/SQLite,
      # backticks on MySQL) so the same column normalizes across adapters.
      normalized_sql = sql.gsub(/["`]/, '')
      normalized_sql = normalized_sql.gsub(CONDITION_CAST, '')
      normalized_sql = expand_exponent_literals(normalized_sql)
      # Gives `IN` one space before its list, so `qty IN(1)` and `qty IN (1)`
      # reach the same string and the list is recognisable to the unwrappers
      # below. `\b` keeps a call such as `min(1)` out of it.
      normalized_sql = normalized_sql.gsub(/\bIN\s*\(/i, 'IN (')
      normalized_sql = normalize_operator_spacing(normalized_sql)
      normalized_sql = unwrap_redundant_parentheses(normalized_sql)
      # Rewrites the SQL inequality operator `<>` to `!=`; the spacing step
      # has already given it a space either side.
      normalized_sql = normalized_sql.gsub('<>', '!=')
      normalized_sql.gsub(/\s+/, ' ').strip
    end

    # Removes the parentheses PostgreSQL puts around an operand it had to cast,
    # which are redundant once the cast itself is gone: `(0)::numeric` -> `0`,
    # `((name)::character varying(3))::text` -> `name`, `(abs(1))::numeric` ->
    # `abs(1)`. Each pass repeats because removing one layer can expose another.
    def unwrap_redundant_parentheses(sql)
      normalized_sql = sql.dup

      true while normalized_sql.gsub!(WRAPPED_IDENTIFIER, '\1')
      true while normalized_sql.gsub!(WRAPPED_NUMBER, '\1')
      true while normalized_sql.gsub!(WRAPPED_FUNCTION_CALL, '\k<call>')

      normalized_sql
    end

    # Repeatedly removes one wrapping layer of parentheses when the whole SQL
    # fragment is enclosed, e.g. `((foo))` -> `foo`.
    def strip_outer_parentheses(sql)
      stripped_sql = sql.strip

      stripped_sql = stripped_sql[1..-2].strip while wrapped_with_parentheses?(stripped_sql)

      stripped_sql
    end

    # Returns true only when the string is entirely wrapped by one outer pair of
    # parentheses, not when parentheses close earlier inside the expression.
    def wrapped_with_parentheses?(sql)
      return false unless sql.start_with?('(') && sql.end_with?(')')

      depth = 0

      sql[1..-2].each_char do |char|
        depth = parenthesis_depth(depth, char)
        return false if depth.negative?
      end

      depth.zero?
    end

    # Tracks parenthesis nesting depth character by character.
    def parenthesis_depth(depth, char)
      case char
      when '('
        depth + 1
      when ')'
        depth - 1
      else
        depth
      end
    end

    # Rewrites shorthand boolean predicates into explicit comparisons so
    # `flag` and `NOT flag` line up with `flag = true/false`.
    def normalize_boolean_predicates(sql)
      normalized_sql = sql.dup

      normalized_sql.gsub!(NEGATED_BOOLEAN_PREDICATE) do
        "#{Regexp.last_match(1)} #{Regexp.last_match(2)} = 0"
      end

      normalized_sql.gsub!(BARE_BOOLEAN_PREDICATE) do
        "#{Regexp.last_match(1)} #{Regexp.last_match(2)} = 1"
      end

      normalized_sql.gsub(/\s+/, ' ').strip
    end

    # Rewrites PostgreSQL's `= ANY (ARRAY[...])` and `<> ALL (ARRAY[...])` forms
    # into the `IN (...)` and `NOT IN (...)` Active Record generates for arrays.
    # `<>` has already become `!=` by this point in the pipeline.
    def normalize_array_any_predicates(sql)
      sql.gsub(ARRAY_MEMBERSHIP_PREDICATE) do
        match = Regexp.last_match
        membership = match[:operator].match?(/ANY/i) ? 'IN' : 'NOT IN'

        "#{match[:column]} #{membership} (#{match[:items].gsub(/\s+/, ' ').strip})"
      end
    end

    # Rewrites negated "blank or nil" predicates into the same shape used by
    # `allow_blank`-derived guards: `IS NOT NULL AND != ''`.
    def normalize_negated_blank_or_nil_predicates(sql)
      sql.gsub(NEGATED_BLANK_OR_NIL_PREDICATE) do
        "#{Regexp.last_match(1)} IS NOT NULL AND #{Regexp.last_match(1)} != ''"
      end
    end

    # Sorts simple `AND` clauses so `a AND b` and `b AND a` normalize to the
    # same string before comparison. Two clauses can be identical apart from the
    # string each one compares against, and then those strings decide the order,
    # which is why the literals go back in before the sort. A placeholder is
    # numbered by where its literal appeared, so sorting on the placeholders
    # would leave such a pair in whichever order it arrived in.
    def sort_and_clauses(sql, literals)
      # Matches `AND` with surrounding whitespace and splits the expression into
      # comparable clause fragments.
      clauses = sql.split(/\s+AND\s+/i)
      return sql if clauses.length == 1

      clauses.map! { |clause| strip_outer_parentheses(clause) }
      clauses.sort_by { |clause| unmask_condition_literals(clause, literals) }.join(' AND ')
    end

    # Builds the implicit SQL guard introduced by validator options that skip
    # nil or blank values instead of validating them.
    def uniqueness_validator_guard_sql(model, attribute, validator)
      attribute_name = foreign_key_or_attribute(model, attribute).to_s

      if validator.options[:allow_blank]
        "#{attribute_name} IS NOT NULL AND #{attribute_name} != ''"
      elsif validator.options[:allow_nil]
        "#{attribute_name} IS NOT NULL"
      end
    end

    # A validator with only `allow_nil` / `allow_blank` and no explicit
    # conditions is still satisfied by a full unique index, because the database
    # constraint is stricter than the validator.
    def validator_guard_only?(model, attribute, validator)
      uniqueness_validator_guard_sql(model, attribute, validator).present? &&
        validator.options[:conditions].nil?
    end

    # @return [String]
    def wrapped_attribute_name(attribute, validator, model)
      attribute = foreign_key_or_attribute(model, attribute)

      if validator.options[:case_sensitive].nil? || validator.options[:case_sensitive]
        attribute
      else
        "lower(#{attribute})"
      end
    end
  end
end
