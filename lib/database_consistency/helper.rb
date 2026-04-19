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

      normalize_condition_sql(where_part.gsub("#{model.quoted_table_name}.", '').gsub('"', ''))
    rescue StandardError
      nil
    end

    # Builds the effective uniqueness constraint enforced by a validator by
    # combining its explicit `conditions` proc with implicit guards such as
    # `allow_nil` / `allow_blank`.
    def uniqueness_validator_where_sql(model, attribute, validator)
      conditions_sql = conditions_where_sql(model, validator.options[:conditions])
      guard_sql = uniqueness_validator_guard_sql(model, attribute, validator)

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

    # Normalizes SQL predicates into a canonical form so semantically equivalent
    # Rails validators and database partial indexes can be compared safely.
    def normalize_condition_sql(sql)
      sql
        .to_s
        .then { |value| strip_outer_parentheses(value) }
        .then { |value| normalize_sql(value) }
        .then { |value| normalize_boolean_predicates(value) }
        .then { |value| normalize_array_any_predicates(value) }
        .then { |value| normalize_negated_blank_or_nil_predicates(value) }
        .then { |value| sort_and_clauses(value) }
    end

    # Applies lightweight SQL normalization without changing the logical meaning.
    def normalize_sql(sql)
      # `/::\w+/` removes PostgreSQL casts like `column::text`.
      normalized_sql = sql.gsub(/::\w+/, '')
      # `/\(([a-z_][\w.]*)\)/i` unwraps a bare identifier surrounded by
      # parentheses, e.g. `(internal_name)` -> `internal_name`.
      normalized_sql = normalized_sql.gsub(/\(([a-z_][\w.]*)\)/i, '\1')
      # `/\bTRUE\b/i` and `/\bFALSE\b/i` normalize boolean literals to `1` / `0`
      # so they match SQL generated by Active Record on some adapters.
      normalized_sql = normalized_sql.gsub(/\bTRUE\b/i, '1').gsub(/\bFALSE\b/i, '0')
      # `/\s*<>\s*/` rewrites the SQL inequality operator `<>` to `!=`.
      normalized_sql = normalized_sql.gsub(/\s*<>\s*/, ' != ')
      # `/\bIS\s+NOT\s+NULL\b/i` normalizes `IS NOT NULL` spacing and casing.
      normalized_sql = normalized_sql.gsub(/\bIS\s+NOT\s+NULL\b/i, ' IS NOT NULL')
      # `/\bIS\s+NULL\b/i` normalizes `IS NULL` spacing and casing.
      normalized_sql = normalized_sql.gsub(/\bIS\s+NULL\b/i, ' IS NULL')
      # `/ = 't'/` and `/ = 'f'/` normalize PostgreSQL boolean literals stored
      # as `'t'` / `'f'` inside comparisons.
      normalized_sql = normalized_sql.gsub(/ = 't'/, ' = 1').gsub(/ = 'f'/, ' = 0')
      # `/\s+/` collapses any run of whitespace to a single space.
      normalized_sql = normalized_sql.gsub(/\s+/, ' ')
      normalized_sql.strip
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

      # Matches a bare negated boolean predicate such as `NOT archived`
      # appearing at the start of an expression, after `AND` / `OR`, or after
      # an opening parenthesis, and rewrites it to `archived = 0`.
      normalized_sql.gsub!(
        /(^|(?:\bAND\b|\bOR\b|\())\s*NOT\s+([a-z_][\w.]*)\s*(?=$|(?:\bAND\b|\bOR\b|\)))/i
      ) { "#{Regexp.last_match(1)} #{Regexp.last_match(2)} = 0" }

      # Matches a bare boolean predicate such as `most_recent` appearing in the
      # same structural positions, and rewrites it to `most_recent = 1`.
      normalized_sql.gsub!(
        /(^|(?:\bAND\b|\bOR\b|\())\s*([a-z_][\w.]*)\s*(?=$|(?:\bAND\b|\bOR\b|\)))/i
      ) { "#{Regexp.last_match(1)} #{Regexp.last_match(2)} = 1" }

      normalized_sql.gsub(/\s+/, ' ').strip
    end

    # Rewrites PostgreSQL's `= ANY (ARRAY[...])` form into an `IN (...)` form
    # so it matches the SQL Active Record typically generates for arrays.
    def normalize_array_any_predicates(sql)
      sql.gsub(
        # Matches `column = ANY (ARRAY[...])`, capturing the column name and the
        # full array payload so it can be converted to `column IN (...)`.
        /([a-z_][\w.]*)\s*=\s*ANY\s*\(ARRAY\[(.*?)\]\)/i
      ) { "#{Regexp.last_match(1)} IN (#{Regexp.last_match(2).gsub(/\s+/, ' ').strip})" }
    end

    # Rewrites negated "blank or nil" predicates into the same shape used by
    # `allow_blank`-derived guards: `IS NOT NULL AND != ''`.
    def normalize_negated_blank_or_nil_predicates(sql)
      sql.gsub(
        # Matches SQL like `NOT (column = '' OR column IS NULL)` while enforcing
        # the same column name on both sides via backreference `\1`.
        /NOT\s+\(\s*\(?([a-z_][\w.]*)\s*=\s*''\s+OR\s+\1\s+IS\s+NULL\)?\s*\)/i
      ) { "#{Regexp.last_match(1)} IS NOT NULL AND #{Regexp.last_match(1)} != ''" }
    end

    # Sorts simple `AND` clauses so `a AND b` and `b AND a` normalize to the
    # same string before comparison.
    def sort_and_clauses(sql)
      # Matches `AND` with surrounding whitespace and splits the expression into
      # comparable clause fragments.
      clauses = sql.split(/\s+AND\s+/i)
      return sql if clauses.length == 1

      clauses.map! { |clause| strip_outer_parentheses(clause) }
      clauses.sort.join(' AND ')
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
