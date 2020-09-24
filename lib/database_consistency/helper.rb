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
  end
end
