# frozen_string_literal: true

module DatabaseConsistency
  # The module contains helper methods
  module Helper
    module_function

    # Returns list of models to check
    def models
      ActiveRecord::Base.descendants.delete_if(&:abstract_class?).delete_if do |klass|
        !klass.connection.table_exists?(klass.table_name) || klass.name.include?('HABTM_')
      end
    end

    # Return list of not inherited models
    def parent_models
      models.group_by(&:table_name).each_value.map do |models|
        models.min_by { |model| models.include?(model.superclass) ? 1 : 0 }
      end
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
      ([wrapped_attribute_name(attribute, validator)] + scope_columns(validator, model)).map(&:to_s)
    end

    def scope_columns(validator, model)
      Array.wrap(validator.options[:scope]).map do |scope_item|
        model._reflect_on_association(scope_item)&.foreign_key || scope_item
      end
    end

    # @return [String]
    def wrapped_attribute_name(attribute, validator)
      if validator.options[:case_sensitive].nil? || validator.options[:case_sensitive]
        attribute
      else
        "lower(#{attribute})"
      end
    end
  end
end
